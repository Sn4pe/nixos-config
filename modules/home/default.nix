{ user, ... }:
{
  imports = [
    ./apps.nix
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
}
