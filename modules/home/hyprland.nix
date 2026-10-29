# De kadachi (kasane/desktop/hyprland + kasane/theme), con teclado es en vez de dvorak
# Config en Lua (hyprlang está obsoleto desde 0.55): opciones, monitores y escritorios como
# atributos de Nix (hl.config/hl.monitor/hl.workspace_rule); binds y autoarranque en .lua
{ osConfig, pkgs, ... }:
let
  cursor = osConfig.stylix.cursor;

  # En Lua, `hyprctl dispatch` espera un dispatcher de Lua; en script para no pelear con las comillas en hypridle.conf.
  # Si responde otra cosa (sesión hyprlang aún abierta tras el switch), usa la sintaxis antigua
  dpms =
    action:
    let
      legacy = if action == "enable" then "on" else "off";
    in
    pkgs.writeShellScript "hypr-dpms-${action}" ''
      hyprctl dispatch 'hl.dsp.dpms({ action = "${action}" })' | grep -q '^ok' || hyprctl dispatch dpms ${legacy}
    '';

  # Los dos MSI son iguales: se distinguen por el número de serie, no por el puerto HDMI
  # (así no se intercambian si cambias los cables). Ver `hyprctl monitors`
  left = "desc:Microstep MSI MP273A PB4H603502628";
  right = "desc:Microstep MSI MP273A PB4H603502614";

in
{
  home.packages = with pkgs; [
    awww
    grim
    slurp
    satty # anotar capturas (lo más parecido a ShareX, que solo existe en Windows)
  ];

  programs.hyprlock.enable = true;

  # Bloquea a los 10 min y apaga la pantalla a los 15; sin suspender (Docker/fine-tuning)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${dpms "enable"}";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "${dpms "disable"}";
          on-resume = "${dpms "enable"}";
        }
      ];
    };
  };

  # Historial del portapapeles; se abre con Super+Shift+V
  services.cliphist.enable = true;
  programs.fuzzel.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # El paquete lo pone el módulo de NixOS; UWSM se encarga de la sesión
    package = null;
    portalPackage = null;
    systemd.enable = false;

    settings = {
      # Monitor automático. Para fijarlo: { output = "DP-1"; mode = "2560x1440@165"; position = "0x0"; scale = 1; }
      # Monitor 4K: scale = 1.5 y config.xwayland.force_zero_scaling = true
      # Los dos MSI a izquierda y derecha, como están en la mesa; cualquier otro, en automático
      monitor = [
        {
          output = left;
          mode = "1920x1080@100"; # preferred da 60 Hz en estos MSI
          position = "0x0";
          scale = 1;
        }
        {
          output = right;
          mode = "1920x1080@100";
          position = "1920x0";
          scale = 1;
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        }
      ];

      # Los 10 escritorios siempre visibles en la barra: 1-5 a la izquierda, 6-10 a la derecha
      workspace_rule = builtins.genList (i: {
        workspace = toString (i + 1);
        monitor = if i < 5 then left else right;
        persistent = true;
        default = i == 0 || i == 5;
      }) 10;

      config = {
        input = {
          kb_layout = "es";
          accel_profile = "flat";
        };

        # Huecos, desenfoque y bordes redondeados
        general = {
          gaps_in = 4;
          gaps_out = 8;
        };
        decoration = {
          rounding = 12;
          blur = {
            enabled = true;
            size = 2;
            passes = 3;
          };
          dim_inactive = true;
          dim_strength = 0.4;
          shadow.enabled = false;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          middle_click_paste = false;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };
    };

    extraLuaFiles = {
      # Las apps se lanzan con `uwsm app --` para que cada una tenga su propio servicio
      autostart = ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("hyprctl setcursor ${cursor.name} ${toString cursor.size}")
          hl.exec_cmd("uwsm app -- awww-daemon")
          hl.exec_cmd("sleep 1 && awww img ${osConfig.stylix.image}")
        end)
      '';

      binds = ''
        hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
        hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- pcmanfm-qt"))
        hl.bind("SUPER + B", hl.dsp.exec_cmd("uwsm app -- firefox"))
        hl.bind("SUPER + Q", hl.dsp.window.close())
        hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
        hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
        hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
        hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
        hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

        -- Captura de zona / pantalla completa → satty para anotar, copiar o guardar
        hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename - --copy-command wl-copy --early-exit]]))
        hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | satty --filename - --copy-command wl-copy --early-exit"))

        hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
        hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
        hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
        hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

        -- Super+1…0 va al escritorio 1…10; con Shift mueve la ventana y la sigue
        for i = 1, 10 do
          local key = tostring(i % 10)
          local ws = tostring(i)
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = ws }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = true }))
        end

        -- Mover/redimensionar con SUPER + ratón y teclas de volumen
        hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
      '';
    };
  };
}
