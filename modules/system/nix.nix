{ user, ... }:
{
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };
  nixpkgs.config.allowUnfree = true;

  # De kadachi (defaults/nix): `nh os switch` en vez de `nixos-rebuild`, y limpieza semanal del store
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 14d";
    };
    flake = "/home/${user}/nixos-config";
  };

  # Ejecuta binarios precompilados (protoc de npm, wheels de Python, servidores de lenguaje de Zed)
  # que en NixOS normalmente fallan con "No such file or directory"
  programs.nix-ld.enable = true;
}
