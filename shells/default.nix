# Entornos por proyecto ocasional; lo de uso diario va global en modules/home. En la carpeta del proyecto:
#   echo 'use flake /etc/nixos#ml' > .envrc && direnv allow
# o, sin direnv, para algo puntual:  nix develop /etc/nixos#ml
{ pkgs }:
{
  ml = import ./ml.nix { inherit pkgs; };
}
