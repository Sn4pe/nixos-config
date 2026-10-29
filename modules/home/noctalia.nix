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
        end = [
          "media"
          "cpu"
          "gpu"
          "ram"
          "caffeine"
          "notifications"
          "tray"
          "bluetooth"
          "volume"
          "date"
          "clock"
        ];
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
