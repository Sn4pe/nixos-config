{
  pkgs,
  user,
  hostName,
  ...
}:
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8";
  console.keyMap = "es";

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };
  nixpkgs.config.allowUnfree = true;

  # De kadachi: `nh os switch` en vez de `nixos-rebuild`, y limpieza semanal del store
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 14d";
    };
    flake = "/home/${user}/nixos-config";
  };

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  # agentos levanta todo con `docker compose`
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Ejecuta binarios precompilados (protoc de npm, wheels de Python, servidores de lenguaje de Zed)
  # que en NixOS normalmente fallan con "No such file or directory"
  programs.nix-ld.enable = true;

  # Escritorio: Hyprland lanzado con UWSM, igual que en kadachi
  programs = {
    uwsm.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    zsh.enable = true;
    noctalia.enable = true;
  };
  users.defaultUserShell = pkgs.zsh;
  hardware.bluetooth.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
  };

  xdg.portal = {
    enable = true;
    config.common.default = "gtk";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # De kadachi (megurine/is/desktop): audio, montaje de USB y polkit
  security.polkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    udisks2.enable = true;
    gvfs.enable = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    git
    wl-clipboard
  ];

  # No lo cambies aunque actualices: indica con qué versión se instaló
  system.stateVersion = "26.05";
}
