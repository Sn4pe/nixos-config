# sprint: resumen corto para la review del sprint, sacado de Jira (AGOS), PRs y commits de AIRInstitute.
# El modelo solo reescribe la lista de hechos: si cita algo que no está en ella, se da la lista tal cual
{ pkgs, ... }:
let
  model = "gemma4:26b-a4b-it-qat";
  board = "203"; # Pizarra AGENT-OS

  sprint = pkgs.writeShellApplication {
    name = "sprint";
    runtimeInputs = with pkgs; [
      jq
      curl
      gh
      git
      gawk
      coreutils
      wl-clipboard
    ];
    excludeShellChecks = [ "SC1090" ]; # el env de Jira vive fuera del repo
    text = ''
      [[ -n ''${JIRA_API_TOKEN:-} ]] || { set -a; . ~/.config/jira/env; set +a; }
      jira() { curl -sf -G -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") "''${JIRA_BASE_URL%/}$1" "''${@:2}"; }

      # Sin argumento: el activo si acaba en 2 días o menos (la review es al final), si no el último cerrado
      # shortcut: solo mira los 50 primeros sprints del tablero, paginar con startAt si llega a más
      sprints=$(jira "/rest/agile/1.0/board/${board}/sprint" --data-urlencode state=active,closed --data-urlencode maxResults=50)
      sp=$(jq -c --arg id "''${1:-}" '.values | if $id != "" then map(select(.id == ($id | tonumber)))[0]
        else (map(select(.state == "active" and (.endDate[:19] + "Z" | fromdate) - now < 172800))[0]
          // (map(select(.state == "closed")) | max_by(.endDate))) end' <<<"$sprints")
      [[ $sp != null ]] || { echo "No encuentro el sprint ''${1:-}" >&2; exit 1; }
      id=$(jq -r .id <<<"$sp")
      name=$(jq -r .name <<<"$sp")
      start=$(jq -r .startDate <<<"$sp")
      end=$(jq -r .endDate <<<"$sp")

      # Hechos: "sección <tab> clave <tab> texto"
      facts=$(mktemp)
      trap 'rm -f "$facts" "$facts.n"' EXIT

      jira /rest/api/2/search --data-urlencode "jql=sprint = $id AND assignee = currentUser()" \
        --data-urlencode fields=summary,status --data-urlencode maxResults=200 |
        jq -r '.issues[] | .fields.status as $s
          | [ (if $s.name == "Bloqueado" then "Bloqueos" elif $s.statusCategory.key == "done" then "Hecho"
               elif $s.statusCategory.key == "new" then "Sin empezar" else "En curso" end),
              .key, "\(.fields.summary) (\($s.name))" ] | @tsv' >>"$facts"

      # PRs mergeados dentro del sprint y los que siguen abiertos
      prs=$(gh search prs --owner AIRInstitute --author @me --updated "''${start:0:10}..''${end:0:10}" \
        --json number,title,state,repository,closedAt --limit 100)
      jq -r --arg s "$start" --arg e "$end" '.[]
        | select((.state == "merged" and .closedAt >= $s and .closedAt <= $e) or .state == "open")
        | [ (if .state == "merged" then "Hecho" else "En curso" end),
            "\(.repository.name)#\(.number)", "PR \(.state): \(.title)" ] | @tsv' <<<"$prs" >>"$facts"

      # Commits solo de repos sin PRs en el sprint: lo que no queda reflejado en otro sitio
      email=$(git config user.email)
      for repo in ~/Projects/*/; do
        git -C "$repo" remote get-url origin 2>/dev/null | grep -q 'github.com[:/]AIRInstitute/' || continue
        r=$(basename "$repo")
        grep -q "^[^\t]*"$'\t'"$r#" "$facts" && continue
        git -C "$repo" log --all --no-merges --author="$email" --since="$start" --until="$end" --format="Otros%x09$r@%h%x09commit: %s" | head -n 10 >>"$facts"
      done

      # Los PRs de un ticket ya listado sobran: Jira lo cuenta mejor. Cada hecho lleva un número
      # para citarlo (el modelo traducía los nombres de repo, p. ej. agentos -> agentes)
      awk -F '\t' -v OFS='\t' 'NR == FNR { if ($2 ~ /^AGOS-/) t[$2]; next }
        { for (k in t) if ($3 ~ ("PR .*" k "([^0-9]|$)")) next; print ++n, $1, $3 " (" $2 ")" }' "$facts" "$facts" >"$facts.n"
      mv "$facts.n" "$facts"

      [[ -s $facts ]] || { echo "Nada en $name"; exit 0; }

      # Lista exacta agrupada por sección, sirve de respaldo y de referencia
      plain=$(for sec in Hecho "En curso" Bloqueos "Sin empezar" Otros; do
        awk -F '\t' -v s="$sec" '$2 == s { if (!n++) print s ":"; print "- " $3 " [" $1 "]" } END { if (n) print "" }' "$facts"
      done)

      prompt=$(printf '%s\n' \
        "Vas a leer en voz alta en la review del sprint lo que he hecho. Reescribe la lista de hechos de <hechos> en español, en primera persona, con frases cortas y fáciles de decir, sin jerga técnica." \
        "Reglas estrictas:" \
        "- Usa las mismas secciones y en el mismo orden (Hecho:, En curso:, Bloqueos:, Sin empezar:, Otros:), solo las que aparecen. No muevas nada de sección." \
        "- Cada línea empieza por '- ' y termina con los números de los hechos que resume entre corchetes, separados por coma, p. ej. [3, 7]." \
        "- Todos los números tienen que salir. Junta en una línea los hechos que traten de lo mismo. Máximo 10 líneas en total." \
        "- No cites claves de ticket ni nombres de repositorio: solo los números." \
        "- No añadas nada que no esté en la lista: ni causas, ni planes, ni resultados, ni claves nuevas." \
        "- Si no estás seguro de cómo decir algo sin cambiar su sentido, usa las palabras del hecho tal cual." \
        "- Solo texto plano, sin markdown ni negritas, sin introducción ni despedida." \
        "<hechos>" "$plain" "</hechos>")

      text=$(jq -n --arg p "$prompt" '{ model: "${model}", prompt: $p, stream: false, think: false,
          keep_alive: "1m", options: { temperature: 0.1, num_predict: 600 } }' |
        curl -sf --max-time 300 localhost:11434/api/generate -d @- | jq -r '.response // empty') || text=""

      # Cada línea cita algún hecho de su sección y no falta ninguno
      ok=$(awk -F '\t' 'NR == FNR { sec[$1] = $2; next }
        /^(Hecho|En curso|Bloqueos|Sin empezar|Otros):$/ { cur = substr($0, 1, length($0) - 1); next }
        /^[[:space:]]*$/ { next }
        !/^- .*\[[0-9, ]+\]$/ || cur == "" { bad = 1; next }
        { k = $0; sub(/.*\[/, "", k); sub(/\]$/, "", k); n = split(k, ks, /, */)
          for (i = 1; i <= n; i++) { if (sec[ks[i]] != cur) bad = 1; seen[ks[i]] } }
        END { for (f in sec) if (!(f in seen)) bad = 1; print (bad || !length(seen)) ? "no" : "si" }' "$facts" - <<<"$text")

      if [[ $ok != si ]]; then
        [[ -n $text ]] && echo "(El modelo se salió de la lista: va la lista exacta)" >&2
        text=$plain
      fi

      out="''${XDG_STATE_HOME:-$HOME/.local/state}/sprint"
      mkdir -p "$out"
      report=$(printf '%s (%s a %s)\n\n%s\n\n---- Lista exacta ----\n\n%s\n' \
        "$name" "''${start:0:10}" "''${end:0:10}" "$text" "$plain")
      printf '%s\n' "$report" >"$out/$name.md"
      printf '%s\n' "$text" | wl-copy 2>/dev/null || true
      printf '%s\n\nGuardado en %s (resumen copiado)\n' "$report" "$out/$name.md"
    '';
  };
in
{
  home.packages = [ sprint ];
}
