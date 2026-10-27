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

  # Firmware de Wi-Fi/Bluetooth/GPU y actualizaciones de BIOS/SSD con `fwupdmgr update`
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

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
