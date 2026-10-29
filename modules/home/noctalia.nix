# De kadachi (kasane/desktop/noctalia): barra arriba, notificaciones, lanzador y menú de apagado
{ osConfig, ... }:
let
  ipc = "noctalia msg";
in
{
  programs.noctalia = {
    enable = true;
    settings = {
      audio.enable_sounds = false;

      # Del catálogo community: Tailscale (equipos de la tailnet) y uso de Claude (límites de 5 h y semanal).
      # Esto solo los marca: la primera vez hay que descargarlos con `noctalia msg plugins enable <id>`.
      # claudecode lee ~/.claude/.credentials.json y renueva el token si caduca
      plugins.enabled = [
        "rylos/tailnet"
        "jrohland/claudecode"
      ];

      bar.default = {
        enabled = true;
        position = "top";
        background_opacity = osConfig.stylix.opacity.terminal;
        margin_edge = 8;
        margin_ends = 8;
        start = [
          "launcher"
          "workspaces"
        ];
        center = [ "active_window" ];
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
              {
                id = "sys";
                members = [
                  "cpu"
                  "gpu"
                  "ram"
                ];
              }
              {
                id = "svc";
                members = [
                  "jrohland/claudecode:pill"
                  "rylos/tailnet:bar"
                ];
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
              # Solo los usa el monitor derecho
              {
                id = "apps";
                members = [ "taskbar" ];
              }
              {
                id = "music";
                members = [ "media" ];
              }
            ];
        # Monitor derecho (Slack, Spotify, docs): sin estadísticas ni bandeja, que ya están a la izquierda.
        # match por número de serie, como en hyprland.nix
        monitor.secundario = {
          match = "PB4H603502614";
          start = [ "workspaces" ];
          # active_window enseña la ventana con foco de cualquier monitor; taskbar solo las de este
          center = [ "group:apps" ];
          end = [ "group:music" ];
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
        # Menú de Ctrl+Alt+Supr: apagar, reiniciar, bloquear, bloquear y suspender
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
            {
              action = "lock_and_suspend";
              countdown_seconds = 3.0;
              enabled = true;
              shortcut = "4";
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
        # Que el título del centro no choque con la música
        active_window.max_length = 200.0;
        media.max_length = 160.0;
        gpu = {
          type = "sysmon";
          stat = "gpu_usage";
        };
        tray.drawer = true; # iconos de la bandeja agrupados en un desplegable
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
