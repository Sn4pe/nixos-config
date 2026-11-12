# Herdr (herdr.dev): la app y su runtime herdr-core (`hc`), binarios oficiales de releases.herdr.dev.
# Lo mismo que su install.sh, pero en el store y fijado por hash: se actualiza con ./update.sh
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libGL,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

let
  # Versiones y hashes de releases.herdr.dev/{app,core}/latest.json
  app = {
    version = "0.1.14";
    hash = "sha256-R1o4P49DnjGRqGY1tcEobOTf0tn83x58vf3Wxxdvj/M=";
  };
  core = {
    version = "0.1.19";
    hash = "sha256-Stz7Qj1S8kxcxKHizS/K0fYtKLt3h2rEcsKQgqPqpCQ=";
  };

  coreSrc = fetchurl {
    url = "https://releases.herdr.dev/core/${core.version}/herdr-core-linux-x86_64.tar.gz";
    inherit (core) hash;
  };
in
stdenv.mkDerivation {
  pname = "herdr";
  inherit (app) version;

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${app.version}/herdr-app-linux-x86_64.tar.gz";
    inherit (app) hash;
  };

  sourceRoot = ".";
  postUnpack = "tar -xzf ${coreSrc}";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 herdr-core "$out/bin/herdr-core"
    ln -s herdr-core "$out/bin/hc"
    install -Dm755 herdr-app/herdr-app "$out/lib/herdr/herdr-app"
    install -Dm644 herdr-app/herdr-app.svg "$out/share/icons/hicolor/scalable/apps/herdr-app.svg"

    # Vulkan, EGL y Wayland los abre con dlopen; el core lo busca en el PATH
    makeWrapper "$out/lib/herdr/herdr-app" "$out/bin/herdr-app" \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libGL
          libxkbcommon
          vulkan-loader
          wayland
        ]
      } \
      --prefix PATH : "$out/bin"

    # La misma entrada que escribe su install.sh
    install -Dm644 /dev/stdin "$out/share/applications/herdr-app.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=Herdr
    Comment=Terminals and coding agents that keep running
    Exec=$out/bin/herdr-app
    Icon=herdr-app
    Terminal=false
    Categories=Development;
    StartupWMClass=herdr-app
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Terminals and coding agents that keep running";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-app";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
