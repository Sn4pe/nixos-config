# La palabra del día en la terminal: `wordle-es`, o `wordle-es -l` en una sola línea
{ inputs, pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../../pkgs/wordle-es { src = inputs.wordle-es; }) ];
}
