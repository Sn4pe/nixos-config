# De kadachi (kasane/theme): Stylix pinta GTK, Qt, kitty, Hyprland, Zed... con la misma paleta.
# Oscuro (Mocha) por defecto; el claro (Latte) es una specialisation:
#   tema-claro / tema-oscuro  (alias de zsh), o elígelo en el menú de arranque
{ pkgs, lib, ... }:
let
  catppuccin = flavor: "${pkgs.base16-schemes}/share/themes/catppuccin-${flavor}.yaml";
in
{
  stylix = {
    enable = true;
    base16Scheme = catppuccin "mocha";
    polarity = "dark";
    image = ../../assets/blossoms.jpg;
    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
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

  specialisation.claro.configuration.stylix = {
    base16Scheme = lib.mkForce (catppuccin "latte");
    polarity = lib.mkForce "light";
    cursor.name = lib.mkForce "phinger-cursors-light";
  };
}
