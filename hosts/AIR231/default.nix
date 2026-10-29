# Lo propio de esta máquina. Otra máquina = otra carpeta en hosts/ y otra entrada en flake.nix
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix # lo genera el instalador: cp /etc/nixos/hardware-configuration.nix hosts/AIR231/
    ./nvidia.nix # RTX 4080
    ./data.nix # segundo NVMe en /data
    ./ollama.nix
    "${inputs.secrets}/AIR231/inventory.nix" # agente OCS de AIR; está en el repo privado
  ];

  # Que `nh clean` no borre el repo privado del store: el agente OCS lo evalúa a diario como root,
  # que no tiene la sesión de `gh` para volver a descargarlo
  system.extraDependencies = [ inputs.secrets ];

  # No lo cambies aunque actualices: indica con qué versión se instaló
  system.stateVersion = "26.05";
}
