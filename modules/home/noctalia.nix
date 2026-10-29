# De kadachi (kasane/desktop/noctalia): barra arriba, notificaciones, lanzador y menú de apagado
{ config, osConfig, ... }:
let
  ipc = "noctalia msg";
in
{
  programs.noctalia = {
    enable = true;
    settings = {
      audio.enable_sounds = false;
      # Bloquea hyprlock (hypridle, ver hyprland.nix); si no, Noctalia se adelanta con su pantalla gris
      lockscreen.enabled = false;

      # Del catálogo community: Tailscale (equipos de la tailnet) y uso de Claude (límites de 5 h y semanal).
      # Esto solo los marca: la primera vez hay que descargarlos con `noctalia msg plugins enable <id>`.
      # claudecode lee ~/.claude/.credentials.json y renueva el token si caduca
      plugins.enabled = [
        "rylos/tailnet"
        "jrohland/claudecode"
        "raycursive/github-prs" # usa la sesión de `gh`; no guarda tokens
        "dfadon/agentos" # local, ver agentos-bar.nix
      ];
      # PRs que te asignan, que esperan tu revisión y los tuyos, sin los proyectos personales
      plugin_settings."raycursive/github-prs" = {
        rules = [
          "assignee:@me"
          "review-requested:@me"
          "author:@me"
        ];
        # Comodines con *: con "/" casa con owner/repo, sin "/" solo con el nombre del repo
        excluded_repositories = [
          "bladetiers/*"
          "*/shirabe*"
          "tulipjs/*"
        ];
      };

      bar.default = {
        enabled = true;
        position = "top";
        background_opacity = osConfig.stylix.opacity.terminal;
        margin_edge = 8;
        margin_ends = 8;
        start = [ "group:nav" ];
        # Trabajo en el centro: uso de Claude, PRs, develop, Jira y Docker (estos tres se ocultan si no hay nada)
        center = [ "group:dev" ];
        widget_spacing = 10;
        # A la derecha, cada bloque en su cápsula para que no quede todo pegado
        end = [
          "group:sys"
          "group:svc"
          "group:ctl"
          "group:time"
        ];
        capsule_group =
          map
            (g: {
              inherit (g) id members;
              padding = 8.0;
              widget_spacing = 8;
            })
            [
              # Lanzador y escritorios en su cápsula, como los bloques de la derecha
              {
                id = "nav";
                members = [
                  "launcher"
                  "workspaces"
                ];
              }
              {
                id = "desks";
                members = [ "workspaces" ];
              }
              {
                id = "sys";
                members = [
                  "cpu"
                  "gpu"
                  "ram"
                ];
              }
              {
                id = "dev";
                members = [
                  "jrohland/claudecode:pill"
                  "raycursive/github-prs:bar"
                  "dfadon/agentos:develop"
                  "dfadon/agentos:jira"
                  "dfadon/agentos:docker"
                ];
              }
              {
                id = "svc";
                members = [ "rylos/tailnet:bar" ];
              }
              {
                id = "ctl";
                members = [
                  "caffeine"
                  "notifications"
                  "tray"
                  "bluetooth"
                  "volume"
                ];
              }
              {
                id = "time";
                members = [
                  "date"
                  "clock"
                ];
              }
              # Solo la usa el monitor derecho
              {
                id = "music";
                members = [ "media" ];
              }
            ];
        # Monitor derecho (Slack, Spotify, docs): sin estadísticas ni bandeja, que ya están a la izquierda.
        # match por número de serie, como en hyprland.nix
        monitor.secundario = {
          match = "PB4H603502614";
          start = [ "group:desks" ];
          center = [ "group:music" ];
          end = [ ];
        };
      };

      theme.builtin = "Catppuccin";

      notification.layer = "overlay";

      osd = {
        enabled = true;
        position = "bottom_center";
      };

      shell = {
        polkit_agent = true;
        # Menú de Ctrl+Alt+Supr: apagar, reiniciar, bloquear. Sin suspender (ver system/desktop.nix)
        session = {
          grid = true;
          grid_columns = 2;
          actions = [
            {
              action = "shutdown";
              countdown_seconds = 10.0;
              enabled = true;
              shortcut = "1";
              variant = "destructive";
            }
            {
              action = "reboot";
              countdown_seconds = 10.0;
              enabled = true;
              shortcut = "2";
              variant = "default";
            }
            {
              action = "lock";
              countdown_seconds = 0.0;
              enabled = true;
              shortcut = "3";
              variant = "default";
            }
          ];
        };
      };

      wallpaper.enabled = false; # el fondo lo pone awww

      widget = {
        clock.format = "{:%H:%M}";
        "jrohland/claudecode:pill" = {
          pill_metric = "both";
          pill_extras = "countdown";
        };
        media.max_length = 160.0;
        "raycursive/github-prs:bar".hide_when_zero = true;
        gpu = {
          type = "sysmon";
          stat = "gpu_usage";
        };
        tray.drawer = true; # iconos de la bandeja agrupados en un desplegable
        # Números en gris (más claro si está vacío) y el activo en una pastilla del color del texto
        # con el número en contraste; sin iconos de apps ni el azul y morado de serie.
        # En hex de Stylix y no como rol: con un rol oscuro Noctalia pinta el número del mismo color
        workspaces = {
          style = "regular";
          show_icons = false;
          focused_color = "#${config.lib.stylix.colors.base05}";
          occupied_color = "surface_container_highest";
          empty_color = "surface_container";
        };
      };
    };
  };

  wayland.windowManager.hyprland.extraLuaFiles.noctalia = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("uwsm app -- noctalia")
    end)

    hl.bind("SUPER + D", hl.dsp.exec_cmd("${ipc} panel-toggle launcher"))
    hl.bind("SUPER + Space", hl.dsp.exec_cmd("${ipc} panel-toggle launcher"))
    hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("${ipc} panel-toggle session"))
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("${ipc} brightness-up"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${ipc} brightness-down"), { locked = true, repeating = true })
  '';
}
