{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;

  # Si Chrome ya está abierto, mete el enlace en su ventana sin pedir el foco: hay que ir a buscarla
  open-link = pkgs.writeShellScript "open-link" ''
    ${pkgs.google-chrome}/bin/google-chrome-stable "$@" &
    sleep 0.3
    # Sin mover el ratón a la ventana: solo el foco
    hyprctl eval 'hl.config({ cursor = { no_warps = true } })' >/dev/null
    hyprctl dispatch 'hl.dsp.focus({ window = "class:google-chrome" })' >/dev/null
    hyprctl eval 'hl.config({ cursor = { no_warps = false } })' >/dev/null
  '';
in
{
  # Chrome/Firefox reescriben este archivo al hacerse navegador por defecto; sin force,
  # el siguiente `nh os switch` falla con "would be clobbered"
  xdg.configFile."mimeapps.list".force = true;
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
      "x-scheme-handler/http" = "open-link.desktop";
      "x-scheme-handler/https" = "open-link.desktop";
      "text/html" = "open-link.desktop";
    };
  };
  xdg.desktopEntries.open-link = {
    name = "Abrir enlace en Chrome";
    exec = "${open-link} %U";
    noDisplay = true;
    mimeType = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "text/html"
    ];
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
