{ pkgs, ... }:
{
  home.packages = with pkgs; [
    slack
    obsidian
    spotify
    google-chrome
    # Agentes de código que siguen corriendo sin la app abierta, ver pkgs/herdr
    (callPackage ../../pkgs/herdr { })
    # De kadachi: utilidades de escritorio
    pcmanfm-qt
    lxqt.lxqt-archiver
    p7zip
    unrar
    imv
    pavucontrol
    playerctl # teclas multimedia de hyprland.nix
  ];

  # Con el módulo (y no en home.packages) Stylix le pone colores y fuentes, y cambia con `theme`
  programs.zed-editor.enable = true;

  # De kadachi (kasane/programs/multimedia): con MPRIS, playerctl ve mpv y lock-and-pause lo pausa al bloquear
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };

  services.syncthing.enable = true; # panel en http://localhost:8384
}
