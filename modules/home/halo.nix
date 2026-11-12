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
  # Espera a que se borre el menú para que no salga en la captura
  shot = mode: ''sleep 0.3; accioshot capture ${mode} --edit --copy --save "$(xdg-user-dir PICTURES)/accioshot"'';

  terminal = args: "uwsm app -- kitty ${args}";
  compose = "~/Projects/agentos/docker/compose";
  project = key: label: dir: {
    inherit key label;
    icon = "folder-symbolic";
    exec = terminal "--directory ${dir}";
  };
  wallpaperMode = key: mode: {
    inherit key;
    label = "Fondos: ${mode}";
    icon = "preferences-desktop-wallpaper-symbolic";
    exec = "wallpaper-mode ${mode}";
  };

  # Lo que no tiene atajo propio. Iconos del tema (kora), por nombre freedesktop
  menu = {
    label = "Menú";
    items = [
      {
        key = "w";
        label = "Trabajo";
        icon = "applications-development-symbolic";
        items = [
          {
            key = "u";
            label = "Levantar agentos";
            icon = "media-playback-start-symbolic";
            exec = terminal "--directory ${compose} docker compose watch";
          }
          {
            key = "s";
            label = "Parar agentos";
            icon = "media-playback-stop-symbolic";
            # stop y no down: down -v borraría los datos sembrados
            exec = "cd ${compose} && docker compose stop && notify-send agentos 'Stack parado'";
          }
          {
            key = "j";
            label = "Pizarra de Jira";
            icon = "view-grid-symbolic";
            # La URL sale del entorno de Jira y no queda en este repo
            exec = ''. ~/.config/jira/env && xdg-open "''${JIRA_BASE_URL%/}/secure/RapidBoard.jspa?rapidView=203&view=planning"'';
          }
          {
            key = "r";
            label = "Review del sprint";
            icon = "x-office-calendar-symbolic";
            exec = terminal "--hold sprint";
          }
          {
            key = "p";
            label = "Pull requests";
            icon = "view-list-symbolic";
            exec = "noctalia msg panel-toggle sn4pe/octobar:panel";
          }
        ];
      }
      {
        key = "p";
        label = "Proyectos";
        icon = "folder-open-symbolic";
        items = [
          (project "a" "agentos" "~/Projects/agentos")
          (project "c" "accioshot" "~/Projects/accioshot")
          (project "h" "halo" "~/Projects/halo")
          (project "e" "eunoia" "~/Projects/eunoia")
          (project "p" "noctalia-plugins" "~/Projects/noctalia-plugins")
          (project "k" "keyfling" "~/Projects/keyfling")
          (project "g" "hyprglance" "~/Projects/hyprglance")
          (project "n" "nixos" "/etc/nixos")
        ];
      }
      {
        key = "a";
        label = "Aspecto";
        icon = "applications-graphics-symbolic";
        items = [
          {
            key = "t";
            label = "Tema claro u oscuro";
            icon = "weather-clear-symbolic";
            exec = "theme";
          }
          {
            key = "f";
            label = "Otro fondo";
            icon = "view-refresh-symbolic";
            exec = "systemctl --user start wallpaper-rotate";
          }
          (wallpaperMode "a" "ascii")
          (wallpaperMode "m" "monet")
          (wallpaperMode "s" "sorolla")
          (wallpaperMode "d" "todos")
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
        key = "s";
        label = "Sistema";
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
          {
            key = "l";
            label = "Bloquear";
            icon = "system-lock-screen-symbolic";
            exec = "loginctl lock-session";
          }
          {
            key = "z";
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
      {
        key = "e";
        label = "Estudiar";
        icon = "accessories-dictionary-symbolic";
        exec = "sh ~/.local/bin/study";
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
