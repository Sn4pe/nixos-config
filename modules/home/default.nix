{ user, ... }:
{
  imports = [
    ./apps.nix
    ./agentos-bar.nix
    ./animations.nix
    ./claude-desktop.nix
    ./dev.nix
    ./shell.nix
    ./hyprland.nix
    ./noctalia.nix
    ./firefox.nix
    ./xdg.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  # No usamos rofi; el target de Stylix aún define el obsoleto `programs.rofi.font`
  # y genera un warning en cada evaluación.
  stylix.targets.rofi.enable = false;
}
