# Bambu Studio: la AppImage oficial (ubu24) de GitHub, más nueva que el bambu-studio de nixpkgs,
# que además es unfree y se compila entero. Se actualiza con ./update.sh
{
  appimageTools,
  fetchurl,
  glib-networking,
  python3,
  runCommand,
}:

let
  pname = "bambu-studio";
  version = "02.09.01.70";
  # Sello de compilación que lleva el nombre del asset
  build = "20261103183404";

  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubu24-v${version}-${build}.AppImage";
    hash = "sha256-Zo2rsb5Tx1gYnta8iZNShd6l4K9GIWVGsbr9aILpr/A=";
  };

  extracted = appimageTools.extractType2 { inherit pname version src; };

  # Segfault al soltar sobre el plater algo que no son ficheros (ver empty-drop.py)
  contents = runCommand "${pname}-${version}-patched" { } ''
    cp -r ${extracted} $out
    chmod u+w $out/bin $out/bin/bambu-studio
    ${python3.interpreter} -I ${./empty-drop.py} ${extracted}/bin/bambu-studio $out/bin/bambu-studio
  '';
in
# wrapAppImage y no wrapType2: este sobreescribe contents con la AppImage extraida sin parchear
appimageTools.wrapAppImage {
  inherit pname version src contents;

  # Lo que la AppImage espera del sistema (Ubuntu 24.04) y no trae dentro
  extraPkgs = pkgs: [ pkgs.webkitgtk_4_1 ];
  # Con NVIDIA el renderer DMA-BUF de WebKit falla (GBM buffer) y deja en blanco los paneles web
  # GIO_MODULE_DIR: sin glib-networking el login de WebKit da "TLS support is not available"
  # LC_ALL=C: lo exporta su AppRun contra segfaults con locales como es_ES, y el wrapper no pasa por AppRun.
  # GDK_BACKEND=x11: el visor 3D (GLEW) se cierra en Wayland nativo
  profile = ''
    export LC_ALL=C
    export GDK_BACKEND=x11
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
    # Como el bambu-studio de nixpkgs (NixOS/nixpkgs#498307): el curl del plugin de red y el login de WebKit
    export WEBKIT_DISABLE_COMPOSITING_MODE=1
    export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    export GIO_MODULE_DIR=${glib-networking}/lib/gio/modules
  '';

  extraInstallCommands = ''
    install -Dm644 ${contents}/BambuStudio.desktop $out/share/applications/bambu-studio.desktop
    substituteInPlace $out/share/applications/bambu-studio.desktop \
      --replace-fail "Exec=AppRun" "Exec=$out/bin/bambu-studio"
    cp -r ${contents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "PC Software for BambuLab's 3D printers";
    homepage = "https://github.com/bambulab/BambuStudio";
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
  };
}
