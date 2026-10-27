# Fine-tuning: Python 3.12 + uv
{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    python312
    uv
  ];
  # Los wheels de pip (torch, etc.) traen binarios que buscan estas librerías;
  # /run/opengl-driver/lib es donde NixOS deja el driver de la GPU (CUDA)
  LD_LIBRARY_PATH =
    pkgs.lib.makeLibraryPath (
      with pkgs;
      [
        stdenv.cc.cc.lib
        zlib
        libGL
        glib
      ]
    )
    + ":/run/opengl-driver/lib";
}
