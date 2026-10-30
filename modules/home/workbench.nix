# Trabajo en la barra de Noctalia: tickets de Jira (AGOS) y contenedores caídos del stack de agentos.
# `workbench-status` lo reúne en un JSON y el plugin local sn4pe/workbench (servicio, dos widgets y un
# panel en workbench/panel.luau) lo enseña. Los commits nuevos en develop los cuenta sn4pe/octobar
# (ver noctalia.nix)
{ lib, pkgs, ... }:
let
  # Pizarra AGENT-OS, para el botón del backlog
  board = "203";

  status = pkgs.writeShellApplication {
    name = "workbench-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      docker-client
    ];
    text = ''
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT

      # Tus tickets abiertos de AGOS (los 50 últimos tocados); el token se lee de ~/.config/jira/env
      # y no sale de aquí
      jira() {
        # shellcheck source=/dev/null
        [ -n "''${JIRA_API_TOKEN:-}" ] || { set -a; . "$HOME/.config/jira/env"; set +a; }
        local base=''${JIRA_BASE_URL%/}
        local jql='project = AGOS AND assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC'
        local state="''${XDG_STATE_HOME:-$HOME/.local/state}/workbench/jira.json"
        get() { timeout 15 curl -sf -G -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") "$base/rest/api/2/$1" "''${@:2}"; }

        local result changes overflow='{}'
        result=$(get search --data-urlencode "jql=$jql" --data-urlencode fields=summary,status,priority \
          --data-urlencode maxResults=50 |
          jq --arg base "$base" --arg url "$base/issues/?jql=$(jq -rn --arg q "$jql" '$q | @uri')" '
            [.issues[] | {
              key,
              summary: .fields.summary,
              status: .fields.status.name,
              category: .fields.status.statusCategory.key,
              priority: (.fields.priority.name // ""),
              url: "\($base)/browse/\(.key)"
            }] as $i
            | {
              ok: true,
              active: [$i[] | select(.category == "indeterminate" and .status != "In Review")] | length,
              review: [$i[] | select(.status == "In Review")] | length,
              issues: $i,
              url: $url,
              backlog: "\($base)/secure/RapidBoard.jspa?rapidView=${board}&view=planning"
            }') || return 1

        # Tickets nuevos y cambios de estado respecto a la pasada anterior. Sin estado previo no se
        # avisa de nada: solo se guarda lo que hay
        changes=$(jq -c --slurpfile prev <(cat "$state" 2>/dev/null || echo null) '
          ($prev[0] // null) as $p
          | if $p == null then [] else
              [.issues[] | select($p[.key] != .status)
               | {key, summary, url, to: .status, from: $p[.key]}
               | .kind = (if .from == null then "assigned" else "status" end)]
            end' <<<"$result")

        # Para lo que ha cambiado, quién lo hizo según el historial; lo tuyo no se avisa
        if [ "$changes" != "[]" ]; then
          # Más de 10 de golpe: el resto conserva su estado anterior y sale en la siguiente pasada
          overflow=$(jq -c '[.[10:][] | {(.key): .from}] | add // {}' <<<"$changes")
          local me
          me=$(get myself | jq -r .key) || me=""
          changes=$(jq -c '.[:10][]' <<<"$changes" | while read -r c; do
            local key field actor
            key=$(jq -r .key <<<"$c")
            field=$(jq -r 'if .kind == "assigned" then "assignee" else "status" end' <<<"$c")
            # Sin historial del campo (se creó ya asignado), cuenta quien creó el ticket
            actor=$(get "issue/$key" --data-urlencode expand=changelog --data-urlencode fields=creator |
              jq -c --arg f "$field" '([.changelog.histories[] | select(any(.items[]; .field == $f))] | last | .author)
                // .fields.creator | {key, name: .displayName}') || actor='{}'
            jq -c --arg me "$me" --argjson a "$actor" 'select($a.key != $me) | .actor = ($a.name // "")' <<<"$c"
          done | jq -s -c .)
        fi

        mkdir -p "$(dirname "$state")"
        jq --argjson o "$overflow" '([.issues[] | {(.key): .status}] | add // {}) + $o | with_entries(select(.value != null))' \
          <<<"$result" >"$state"
        jq --argjson c "$changes" '.changes = $c' <<<"$result"
      }

      # Contenedores agentos-dev-* parados o reiniciándose (los one-shot que acaban con 0 no cuentan).
      # Sin ninguno levantado, el stack está parado a propósito y no se avisa
      docker_() {
        local rows
        rows=$(timeout 10 docker ps -a --filter name=agentos-dev- --format '{{.Names}}\t{{.State}}\t{{.Status}}') || return 1
        printf '%s\n' "$rows" | jq -R -s '
          [split("\n")[] | select(. != "") | split("\t") | {name: .[0], state: .[1], status: .[2]}] as $c
          | ($c | map(select(.state == "running")) | length) as $up
          | ($c | map(select((.state != "running" and (.status | startswith("Exited (0)") | not))
                             or (.status | test("unhealthy|Restarting")))) | map(.name)) as $down
          | {ok: true, down: (if $up == 0 then 0 else ($down | length) end), names: $down}'
      }

      # Las dos en paralelo; si una falla, solo esa sale con ok:false
      jira >"$tmp/jira" 2>/dev/null &
      docker_ >"$tmp/docker" 2>/dev/null &
      wait || true
      for k in jira docker; do [ -s "$tmp/$k" ] || echo '{"ok":false}' >"$tmp/$k"; done
      jq -n --slurpfile j "$tmp/jira" --slurpfile c "$tmp/docker" \
        '{jira: $j[0], docker: $c[0]}'
    '';
  };

  # Cada widget lee su parte del estado que publica el servicio y se oculta si no hay nada
  widget = key: body: ''
    --!nonstrict
    local data = noctalia.state.get("${key}")

    local function render()
      ${body}
    end

    noctalia.state.watch("${key}", function(value)
      data = value
      render()
    end)

    render()

    function update()
      noctalia.setUpdateInterval(5000)
      render()
    end
  '';

  # Ficheros normales y no enlaces: Noctalia no sigue los enlaces al store
  files = {
    "plugin.toml" = pkgs.writeText "plugin.toml" ''
      id = "sn4pe/workbench"
      name = "workbench"
      version = "1.0.0"
      plugin_api = 43
      author = "Sn4pe"
      license = "MIT"
      icon = "briefcase"
      description = "Jira y Docker del trabajo"

      [[service]]
      id = "fetch"
      entry = "service.luau"

      [[widget]]
      id = "jira"
      entry = "jira.luau"

      [[widget]]
      id = "docker"
      entry = "docker.luau"

      [[panel]]
      id = "panel"
      entry = "panel.luau"
      width = 560
      height = 600
      placement = "attached"
      position = "auto"
      open_near_click = true
    '';

    # Cada 3 min: cada pasada es una llamada a Jira
    "service.luau" = pkgs.writeText "service.luau" ''
      --!nonstrict
      local running = false
      local lastRefresh = noctalia.state.get("refresh_requested") or 0
      local lastAck = noctalia.state.get("ack_requested") or 0

      -- Novedades sin ver (tickets asignados y cambios de estado), guardadas para no perderlas al reiniciar
      local eventsFile = noctalia.pluginDataDir() .. "/events.json"
      local raw = noctalia.readFile(eventsFile)
      local events = type(raw) == "string" and raw ~= "" and noctalia.json.decode(raw) or {}
      if type(events) ~= "table" then events = {} end

      local function saveEvents()
        noctalia.mkdirAll(noctalia.pluginDataDir())
        noctalia.writeFile(eventsFile, noctalia.json.encode(events))
        noctalia.state.set("events", events)
      end

      local function addChanges(changes)
        if type(changes) ~= "table" or #changes == 0 then return end
        for _, c in ipairs(changes) do
          table.insert(events, 1, c)
          local what = c.kind == "assigned" and "Te lo han asignado" or `{c.from} -> {c.to}`
          local who = (c.actor or "") ~= "" and `{c.actor}: ` or ""
          noctalia.notify(`{c.key} {c.summary}`, who .. what)
        end
        while #events > 50 do table.remove(events) end
        saveEvents()
      end

      local function fetch()
        if running then return end
        running = true
        -- Por el PATH y no por la ruta del store: así un rebuild del script no obliga a reiniciar el servicio
        noctalia.runAsync("workbench-status", function(result)
          running = false
          if result.timedOut or result.exitCode ~= 0 or result.stdoutTruncated then
            noctalia.log("workbench: workbench-status failed")
            return
          end
          local data = noctalia.json.decode(result.stdout or "")
          if type(data) ~= "table" then return end
          noctalia.state.set("jira", data.jira)
          noctalia.state.set("docker", data.docker)
          if type(data.jira) == "table" then addChanges(data.jira.changes) end
        end, 40000)
      end

      -- Botón "Marcar como visto" del panel
      noctalia.state.watch("ack_requested", function(value)
        local nonce = tonumber(value) or 0
        if nonce ~= lastAck then
          lastAck = nonce
          events = {}
          saveEvents()
        end
      end)

      -- Botón de refrescar del panel
      noctalia.state.watch("refresh_requested", function(value)
        local nonce = tonumber(value) or 0
        if nonce ~= lastRefresh then
          lastRefresh = nonce
          fetch()
        end
      end)

      noctalia.state.set("events", events)
      noctalia.setUpdateInterval(180000)
      fetch()

      function update()
        fetch()
      end
    '';

    # Ticket con en curso · en revisión, y una campana con las novedades sin ver
    "jira.luau" = pkgs.writeText "jira.luau" ''
      --!nonstrict
      local data = noctalia.state.get("jira")
      local events = noctalia.state.get("events") or {}

      local function render()
        local hasTickets = data and data.ok and (data.active > 0 or data.review > 0)
        if not hasTickets and #events == 0 then
          barWidget.setVisible(false)
          return
        end
        barWidget.setVisible(true)
        local children = {
          ui.glyph({ name = "ticket", size = 16, color = "on_surface" }),
          ui.label({ text = hasTickets and `{data.active} · {data.review} rev` or "0", color = "on_surface" }),
        }
        if #events > 0 then
          table.insert(children, ui.glyph({ name = "bell", size = 16, color = "primary" }))
          table.insert(children, ui.label({ text = tostring(#events), color = "primary" }))
        end
        local container = barWidget.isVertical() and ui.column or ui.row
        barWidget.render(container({ gap = 4, align = "center", paddingH = 4 }, children))
      end

      noctalia.state.watch("jira", function(value)
        data = value
        render()
      end)

      noctalia.state.watch("events", function(value)
        events = value or {}
        render()
      end)

      render()

      function update()
        noctalia.setUpdateInterval(5000)
        render()
      end

      function onClick()
        noctalia.togglePanel("sn4pe/workbench:panel")
      end
    '';

    "docker.luau" = pkgs.writeText "docker.luau" (
      widget "docker" ''
        if not data or not data.ok or data.down == 0 then
          barWidget.setVisible(false)
          return
        end
        barWidget.setVisible(true)
        barWidget.setGlyph("brand-docker")
        barWidget.setGlyphColor("error")
        barWidget.setText(tostring(data.down))
        barWidget.setTooltip("Parados: " .. table.concat(data.names or {}, ", "))
      ''
      + ''
        function onClick()
          noctalia.togglePanel("sn4pe/workbench:panel")
        end
      ''
    );

    "panel.luau" = ./workbench/panel.luau;
  };
  plugin = pkgs.runCommand "noctalia-plugin-workbench" { } (
    "mkdir $out\n"
    + lib.concatStrings (lib.mapAttrsToList (name: src: "cp ${src} $out/${name}\n") files)
  );
in
{
  home.packages = [ status ]; # también a mano: `workbench-status | jq`
  # Fuente local de plugins: `noctalia msg plugins source add dfadon path ~/.local/share/noctalia-plugins`
  xdg.dataFile."noctalia-plugins/workbench".source = plugin;
}
