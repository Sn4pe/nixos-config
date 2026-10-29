# De kadachi (kasane/theme): Stylix pinta GTK, Qt, kitty, Hyprland, Noctalia, Zed... con la misma paleta.
# Claro (Latte) por defecto. El oscuro (Mocha) es la specialisation `dark` de Home Manager, no de NixOS:
# así no duplica las entradas del menú de arranque y se cambia al momento, sin reiniciar:
#   "Toggle theme" en el lanzador, o `theme [light|dark]` en la terminal
# Al reiniciar o tras `nh os switch` se vuelve a claro.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  catppuccin = flavor: "${pkgs.base16-schemes}/share/themes/catppuccin-${flavor}.yaml";

  hm = config.home-manager.users.${user};

  # Activa la generación de Home Manager del tema elegido y recarga lo que ya está abierto
  theme = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      libnotify
    ];
    text = ''
      base=${hm.home.activationPackage}
      current=$(readlink "$HOME/.local/state/home-manager/gcroots/current-home" || true)

      case "''${1:-}" in
        light | dark) mode=$1 ;;
        "") if [ "$current" = "$base" ]; then mode=dark; else mode=light; fi ;;
        *)
          echo "Usage: theme [light|dark]   (no argument: toggle)" >&2
          exit 1
          ;;
      esac

      if [ "$mode" = dark ]; then
        "$base/specialisation/dark/activate" --driver-version 1
        noctalia msg theme-mode-set dark || true
      else
        "$base/activate" --driver-version 1
        noctalia msg theme-mode-set light || true
      fi

      # kitty relee su config con SIGUSR1; Hyprland, sus colores y el cursor
      pkill -USR1 -x kitty || true
      hyprctl reload || true
      hyprctl setcursor "phinger-cursors-$mode" ${toString config.stylix.cursor.size} || true

      notify-send -a Theme "Theme: $mode" "Some apps (GTK, Qt) apply it when reopened"
    '';
  };
in
{
  stylix = {
    enable = true;
    base16Scheme = catppuccin "latte";
    polarity = "light";
    image = ../../assets/wallpapers/ascii/ascii-magic-1.jpg;
    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 32;
    };
    icons = {
      enable = true;
      package = pkgs.kora-icon-theme;
      light = "kora-light";
      dark = "kora";
    };
    fonts = {
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sizes = {
        applications = 10;
        terminal = 12;
      };
    };
    opacity.terminal = 0.85;
  };

  home-manager.users.${user} = {
    # `theme` activa Home Manager a mano, sin el servicio que aplica `home-manager.backupFileExtension`:
    # si una app ha reescrito un archivo gestionado (Noctalia su config.toml), lo aparta en vez de fallar
    home.backupFileExtension = "bak";

    specialisation.dark.configuration.stylix = {
      base16Scheme = lib.mkForce (catppuccin "mocha");
      polarity = lib.mkForce "dark";
      # El cursor entero: si solo cambias el nombre, pierde el tamaño y el paquete del sistema
      cursor = lib.mkForce (config.stylix.cursor // { name = "phinger-cursors-dark"; });
    };

    xdg.desktopEntries.theme = {
      name = "Toggle theme";
      comment = "Switch between light and dark";
      exec = "theme";
      icon = "preferences-desktop-theme";
      terminal = false;
    };
  };

  environment.systemPackages = [ theme ];
}
