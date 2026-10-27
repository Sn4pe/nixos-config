# De kadachi (kasane/desktop/hyprland + kasane/theme), con teclado es en vez de dvorak
{ osConfig, pkgs, ... }:
let
  cursor = osConfig.stylix.cursor;
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
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # Historial del portapapeles; se abre con Super+Shift+V
  services.cliphist.enable = true;
  programs.fuzzel.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    # El paquete lo pone el módulo de NixOS; UWSM se encarga de la sesión
    package = null;
    portalPackage = null;
    systemd.enable = false;

    settings = {
      # Monitor automático. Para fijarlo: "DP-1, 2560x1440@165, 0x0, 1"
      # Monitor 4K: ", preferred, auto, 1.5" y xwayland.force_zero_scaling = true
      monitor = [ ", preferred, auto, 1" ];

      # Las apps se lanzan con `uwsm app --` para que cada una tenga su propio servicio
      exec-once = [
        "hyprctl setcursor ${cursor.name} ${toString cursor.size}"
        "uwsm app -- awww-daemon"
        "sleep 1 && awww img ${osConfig.stylix.image}"
      ];

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

      # Los 10 escritorios siempre visibles en la barra
      workspace = builtins.genList (i: "${toString (i + 1)}, persistent:true") 10;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        middle_click_paste = false;
      };

      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      bind = [
        "SUPER, Return, exec, uwsm app -- kitty"
        "SUPER, E, exec, uwsm app -- pcmanfm-qt"
        "SUPER, B, exec, uwsm app -- firefox"
        "SUPER, Q, killactive"
        "SUPER, F, fullscreen"
        "SUPER, V, togglefloating"
        "SUPER, L, exec, loginctl lock-session"
        "SUPER SHIFT, E, exec, uwsm stop"
        "SUPER SHIFT, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

        # Captura de zona / pantalla completa → satty para anotar, copiar o guardar
        ", Print, exec, grim -g \"$(slurp)\" - | satty --filename - --copy-command wl-copy --early-exit"
        "SHIFT, Print, exec, grim - | satty --filename - --copy-command wl-copy --early-exit"

        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
      ]
      ++ builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = toString (i + 1);
            key = toString (if i == 9 then 0 else i + 1);
          in
          [
            "SUPER, ${key}, workspace, ${ws}"
            "SUPER SHIFT, ${key}, movetoworkspace, ${ws}"
          ]
        ) 10
      );

      # Mover/redimensionar con SUPER + ratón y teclas de volumen
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
      bindl = [ ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ];
      bindle = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];
    };
  };
}
