# Lo propio de esta máquina. Otra máquina = otra carpeta en hosts/ y otra entrada en flake.nix
{
  imports = [
    ./hardware-configuration.nix # lo genera el instalador: cp /etc/nixos/hardware-configuration.nix hosts/pc/
    # ./nvidia.nix  # descomenta si el PC tiene gráfica NVIDIA
  ];

  # No lo cambies aunque actualices: indica con qué versión se instaló
  system.stateVersion = "26.05";
}
