# Arranque, red, idioma, firmware y herramientas básicas
{ pkgs, hostName, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10; # que /boot no se llene con kernels viejos
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };
  # DNS por interfaz: con la VPN conectada, los dominios internos van por ella y el resto no
  services.resolved.enable = true;

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8";
  console.keyMap = "es";
  # Sin manual de NixOS (nixos-help): se consulta en la web o con el MCP de NixOS, y ahorra tiempo en cada rebuild
  documentation.nixos.enable = false;
  # Distribución por defecto del sistema (localectl, apps X11); Hyprland usa la suya en input.kb_layout
  services.xserver.xkb.layout = "es";

  # Firmware de Wi-Fi/Bluetooth/GPU y actualizaciones de BIOS/SSD con `fwupdmgr update`
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Salud de los discos: aviso en el escritorio si SMART detecta fallos, y scrub mensual
  # de btrfs para encontrar corrupción silenciosa
  services.smartd = {
    enable = true;
    notifications.systembus-notify.enable = true;
  };
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  # Que los logs (Docker incluido) no crezcan sin límite
  services.journald.settings.Journal.SystemMaxUse = "1G";

  # Swap comprimida en RAM (Docker + fine-tuning)
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  environment.systemPackages = with pkgs; [
    git
    wl-clipboard
    pciutils # lspci
    usbutils # lsusb
    htop
    ncdu
    file
    unzip
    libnotify # notify-send
  ];
}
