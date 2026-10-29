# Estado de agentos en la barra de Noctalia: commits nuevos en develop, tickets de Jira (AGOS) y
# contenedores caídos del stack de desarrollo. `agentos-status` lo reúne en un JSON y el plugin
# local dfadon/agentos (servicio + tres widgets) lo enseña. Solo lectura: no hace fetch ni toca el repo
{ lib, pkgs, ... }:
let
  repo = "AIRInstitute/agentos";

  status = pkgs.writeShellApplication {
    name = "agentos-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      git
      gh
      docker-client
    ];
    text = ''
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT

      # Commits de origin/develop que no están en tu develop local (se ponen a 0 al hacer pull)
      develop() {
        local sha behind
        sha=$(git -C "$HOME/Projects/agentos" rev-parse develop) || return 1
        behind=$(timeout 15 gh api "repos/${repo}/compare/$sha...develop" --jq .ahead_by) || return 1
        jq -n --argjson n "$behind" --arg sha "$sha" \
          '{ok: true, behind: $n, url: "https://github.com/${repo}/compare/\($sha)...develop"}'
      }

      # Tus tickets abiertos de AGOS; el token se lee de ~/.config/jira/env y no sale de aquí
      jira() {
        # shellcheck source=/dev/null
        [ -n "''${JIRA_API_TOKEN:-}" ] || { set -a; . "$HOME/.config/jira/env"; set +a; }
        local jql='project = AGOS AND assignee = currentUser() AND statusCategory != Done'
        timeout 15 curl -sf -G -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") \
          "''${JIRA_BASE_URL%/}/rest/api/2/search" \
          --data-urlencode "jql=$jql" --data-urlencode fields=status --data-urlencode maxResults=200 |
          jq --arg url "''${JIRA_BASE_URL%/}/issues/?jql=$(jq -rn --arg q "$jql" '$q | @uri')" '{
            ok: true,
            active: [.issues[] | select(.fields.status.statusCategory.key == "indeterminate" and .fields.status.name != "In Review")] | length,
            review: [.issues[] | select(.fields.status.name == "In Review")] | length,
            url: $url
          }'
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

      # Las tres en paralelo; si una falla, solo esa sale con ok:false
      develop >"$tmp/develop" 2>/dev/null &
      jira >"$tmp/jira" 2>/dev/null &
      docker_ >"$tmp/docker" 2>/dev/null &
      wait || true
      for k in develop jira docker; do [ -s "$tmp/$k" ] || echo '{"ok":false}' >"$tmp/$k"; done
      jq -n --slurpfile d "$tmp/develop" --slurpfile j "$tmp/jira" --slurpfile c "$tmp/docker" \
        '{develop: $d[0], jira: $j[0], docker: $c[0]}'
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
      id = "dfadon/agentos"
      name = "agentos"
      version = "1.0.0"
      plugin_api = 43
      author = "dfadon"
      license = "MIT"
      icon = "git-branch"
      description = "develop, Jira y Docker de agentos"

      [[service]]
      id = "fetch"
      entry = "service.luau"

      [[widget]]
      id = "develop"
      entry = "develop.luau"

      [[widget]]
      id = "jira"
      entry = "jira.luau"

      [[widget]]
      id = "docker"
      entry = "docker.luau"
    '';

    # Cada 3 min: cada pasada es una llamada a GitHub y otra a Jira
    "service.luau" = pkgs.writeText "service.luau" ''
      --!nonstrict
      local running = false

      local function fetch()
        if running then return end
        running = true
        noctalia.runAsync("${lib.getExe status}", function(result)
          running = false
          if result.timedOut or result.exitCode ~= 0 or result.stdoutTruncated then
            noctalia.log("agentos: agentos-status failed")
            return
          end
          local data = noctalia.json.decode(result.stdout or "")
          if type(data) ~= "table" then return end
          noctalia.state.set("develop", data.develop)
          noctalia.state.set("jira", data.jira)
          noctalia.state.set("docker", data.docker)
        end, 40000)
      end

      noctalia.setUpdateInterval(180000)
      fetch()

      function update()
        fetch()
      end
    '';

    "develop.luau" = pkgs.writeText "develop.luau" (
      widget "develop" ''
        if not data or not data.ok or data.behind == 0 then
          barWidget.setVisible(false)
          return
        end
        barWidget.setVisible(true)
        barWidget.setGlyph("git-branch")
        barWidget.setText("+" .. tostring(data.behind))
        barWidget.setTooltip(tostring(data.behind) .. " commits nuevos en develop")
      ''
      + ''
        function onClick()
          if data and data.url then noctalia.runAsync("xdg-open '" .. data.url .. "'") end
        end
      ''
    );

    "jira.luau" = pkgs.writeText "jira.luau" (
      widget "jira" ''
        if not data or not data.ok or (data.active == 0 and data.review == 0) then
          barWidget.setVisible(false)
          return
        end
        barWidget.setVisible(true)
        barWidget.setGlyph("ticket")
        barWidget.setText(tostring(data.active) .. " · " .. tostring(data.review) .. " rev")
        barWidget.setTooltip("AGOS: " .. tostring(data.active) .. " en curso, " .. tostring(data.review) .. " en revisión")
      ''
      + ''
        function onClick()
          if data and data.url then noctalia.runAsync("xdg-open '" .. data.url .. "'") end
        end
      ''
    );

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
          noctalia.runAsync("uwsm app -- kitty lazydocker")
        end
      ''
    );
  };
  plugin = pkgs.runCommand "noctalia-plugin-agentos" { } (
    "mkdir $out\n"
    + lib.concatStrings (lib.mapAttrsToList (name: src: "cp ${src} $out/${name}\n") files)
  );
in
{
  home.packages = [ status ]; # también a mano: `agentos-status | jq`
  # Fuente local de plugins: `noctalia msg plugins source add dfadon path ~/.local/share/noctalia-plugins`
  xdg.dataFile."noctalia-plugins/agentos".source = plugin;
}
