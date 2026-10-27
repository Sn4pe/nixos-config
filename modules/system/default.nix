# Todo lo de sistema que comparte cualquier máquina; lo propio de cada una va en hosts/<nombre>
{
  imports = [
    ./base.nix
    ./nix.nix
    ./users.nix
    ./desktop.nix
    ./theme.nix
    ./dev.nix
    ./vpn.nix
  ];
}
