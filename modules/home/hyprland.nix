# De kadachi (kasane/desktop/hyprland + kasane/theme), con teclado es en vez de dvorak
{ osConfig, pkgs, ... }:
{
  home.packages = with pkgs; [
    awww
    grim
    slurp
    satty # anotar capturas (lo más parecido a ShareX, que solo existe en Windows)
  ];

  programs.hyprlock.enable = true;

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
      monitor = [ ", preferred, auto, 1" ];

      exec-once = [
        "awww-daemon"
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

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      bind = [
        "SUPER, Return, exec, kitty"
        "SUPER, E, exec, pcmanfm-qt"
        "SUPER, B, exec, firefox"
        "SUPER, Q, killactive"
        "SUPER, F, fullscreen"
        "SUPER, V, togglefloating"
        "SUPER, L, exec, hyprlock"
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
