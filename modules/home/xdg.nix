{ config, ... }:
let
  home = config.home.homeDirectory;
in
{
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
    desktop = "${home}/Escritorio";
    documents = "${home}/Documentos";
    download = "${home}/Descargas";
    music = "${home}/Música";
    pictures = "${home}/Imágenes";
    publicShare = "${home}/Público";
    templates = "${home}/Plantillas";
    videos = "${home}/Vídeos";
  };
}
