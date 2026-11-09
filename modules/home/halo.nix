# halo (~/Projects/halo): menú radial que se abre en el cursor, para acciones sin atajo propio.
# Se abre con SUPER + X, SUPER + botón central o dos toques de SUPER. Letra o clic elige,
# BackSpace o el centro vuelve, Escape o un clic fuera cierra
{
  config,
  inputs,
  osConfig,
  pkgs,
  ...
}:
let
  halo = inputs.halo.packages.${pkgs.stdenv.hostPlatform.system}.default;
  colors = config.lib.stylix.colors;

  # `exec` va por /bin/sh cuando el menú ya se ha cerrado
  dispatch = expr: "hyprctl dispatch '${expr}'";
  # Espera a que se borre el menú para que no salga en la captura
  shot = mode: ''sleep 0.3; accioshot capture ${mode} --edit --copy --save "$(xdg-user-dir PICTURES)/accioshot"'';

  # Iconos del tema (kora), por nombre freedesktop
  menu = {
    label = "Menú";
    items = [
      {
        key = "w";
        label = "Ventana";
        icon = "focus-windows-symbolic";
        items = [
          {
            key = "f";
            label = "Flotante";
            icon = "window-restore-symbolic";
            exec = dispatch ''hl.dsp.window.float({ action = "toggle" })'';
          }
          {
            key = "c";
            label = "Centrar";
            icon = "zoom-fit-best-symbolic";
            exec = dispatch "hl.dsp.window.center()";
          }
          {
            key = "m";
            label = "Pantalla completa";
            icon = "view-fullscreen-symbolic";
            exec = dispatch ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'';
          }
          {
            key = "q";
            label = "Cerrar";
            icon = "window-close-symbolic";
            exec = dispatch "hl.dsp.window.close()";
          }
        ];
      }
      {
        key = "c";
        label = "Captura";
        icon = "camera-photo-symbolic";
        items = [
          {
            key = "r";
            label = "Zona";
            icon = "selection-mode-symbolic";
            exec = shot "region";
          }
          {
            key = "l";
            label = "Última zona";
            icon = "view-refresh-symbolic";
            exec = shot "last-region";
          }
          {
            key = "w";
            label = "Ventana";
            icon = "window-new-symbolic";
            exec = shot "window";
          }
          {
            key = "m";
            label = "Monitor";
            icon = "video-display-symbolic";
            exec = shot "monitor";
          }
        ];
      }
      {
        key = "t";
        label = "Interruptores";
        icon = "emblem-system-symbolic";
        items = [
          {
            key = "n";
            label = "No molestar";
            icon = "notifications-disabled-symbolic";
            exec = "noctalia msg notification-dnd-toggle";
          }
          {
            key = "m";
            label = "Micrófono";
            icon = "microphone-sensitivity-muted-symbolic";
            exec = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          }
        ];
      }
      {
        key = "s";
        label = "Sesión";
        icon = "system-shutdown-symbolic";
        items = [
          {
            key = "l";
            label = "Bloquear";
            icon = "system-lock-screen-symbolic";
            exec = "loginctl lock-session";
          }
          {
            key = "s";
            label = "Suspender";
            icon = "weather-clear-night-symbolic";
            exec = "systemctl suspend";
          }
          {
            key = "e";
            label = "Cerrar sesión";
            icon = "system-log-out-symbolic";
            exec = "uwsm stop";
          }
        ];
      }
    ];
  };
in
{
  home.packages = [ halo ];

  xdg.configFile."halo/config.json".text = builtins.toJSON {
    inherit menu;
    double_tap_ms = 350;
    theme = {
      background = "#${colors.base00}ee";
      foreground = "#${colors.base05}";
      accent = "#${colors.base0D}";
      muted = "#${colors.base03}";
      font_family = osConfig.stylix.fonts.sansSerif.name;
      font_size = 11;
    };
  };

  # Residente para que el menú abra al instante: `halo toggle` solo avisa a este proceso
  systemd.user.services.halo = {
    Unit = {
      Description = "Menú radial halo";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${halo}/bin/halo";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Cada toque suelto de SUPER avisa a halo, que cuenta el doble
  wayland.windowManager.hyprland.extraLuaFiles.halo = ''
    hl.bind("SUPER + X", hl.dsp.exec_cmd("halo toggle"))
    hl.bind("SUPER + mouse:274", hl.dsp.exec_cmd("halo toggle"))
    hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("halo tap"), { release = true })
  '';
}
