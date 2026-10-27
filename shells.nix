# Entornos por proyecto. En la carpeta del proyecto:
#   echo 'use flake ~/nixos-config#ml' > .envrc && direnv allow
# o, sin direnv, para algo puntual:  nix develop ~/nixos-config#ml
# Lo de uso diario (Node para agentos) va global en home.nix
{ pkgs }:
{
  ml = pkgs.mkShell {
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
  };
}
