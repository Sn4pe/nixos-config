{ pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@wheel" ];
    };
    # De kadachi (megurine/is/desktop): que un rebuild no congele el escritorio ni las llamadas
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # Deduplicar el store una vez por semana en vez de en cada build (auto-optimise-store frena los rebuilds)
    optimise.automatic = true;
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
    flake = "/etc/nixos";
  };

  # Ejecuta binarios precompilados (protoc de npm, wheels de Python, servidores de lenguaje de Zed)
  # que en NixOS normalmente fallan con "No such file or directory"
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      icu
      libsecret
    ];
  };
}
