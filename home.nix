{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
{
  imports = [
    ./noctalia.nix
    ./firefox.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "26.05";
    packages = with pkgs; [
      nodejs_24 # agentos pide >= 22; sus Dockerfiles usan node:22
      protobuf
      zed-editor
      claude-code
      gh
      slack
      obsidian
      spotify
      google-chrome
      # De kadachi: utilidades de escritorio
      pcmanfm-qt
      lxqt.lxqt-archiver
      p7zip
      unrar
      imv
      mpv
      grim
      slurp
      pavucontrol
      awww
    ];
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      settings.user.email = "dfadon@air-institute.com";
      # Para no subir por error el .envrc a repos que no son tuyos (agentos)
      ignores = [
        ".envrc"
        ".direnv/"
      ];
    };
    # Al entrar en una carpeta con .envrc carga su shell de Nix (ver shells.nix)
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    hyprlock.enable = true;
    kitty = {
      enable = true;
      settings = {
        enable_audio_bell = "no";
        window_padding_width = 8;
        scrollback_lines = 8000;
      };
    };

    # De kadachi (kasane/zsh), sin el modo vim
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      history.path = "${config.xdg.dataHome}/zhistory";
      syntaxHighlighting.enable = true;
      initContent = ''
        setopt AUTO_PUSHD SHARE_HISTORY MENUCOMPLETE
        autoload -U history-search-end
        zle -N history-beginning-search-backward-end history-search-end
        zle -N history-beginning-search-forward-end history-search-end
        bindkey "^[OA" history-beginning-search-backward-end
        bindkey "^[OB" history-beginning-search-forward-end
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      '';
      shellAliases = {
        rbd = "nh os switch";
        tema-claro = "sudo /nix/var/nix/profiles/system/specialisation/claro/bin/switch-to-configuration test";
        tema-oscuro = "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test";
      };
    };
    starship.enable = true;
  };

  services.syncthing.enable = true; # panel en http://localhost:8384

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "pcmanfm-qt.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "application/pdf" = "firefox.desktop";
    };
  };

  # De kadachi (kasane/misc/spanish-xdg-user-dirs): carpetas del home en castellano
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Escritorio";
    documents = "${config.home.homeDirectory}/Documentos";
    download = "${config.home.homeDirectory}/Descargas";
    music = "${config.home.homeDirectory}/Música";
    pictures = "${config.home.homeDirectory}/Imágenes";
    publicShare = "${config.home.homeDirectory}/Público";
    templates = "${config.home.homeDirectory}/Plantillas";
    videos = "${config.home.homeDirectory}/Vídeos";
  };

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

      # De kadachi (kasane/theme): huecos, desenfoque y bordes redondeados
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
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"

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

      # De kadachi: mover/redimensionar con SUPER + ratón y teclas de volumen
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
