{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
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
    pavucontrol
  ];

  services.syncthing.enable = true; # panel en http://localhost:8384
}
