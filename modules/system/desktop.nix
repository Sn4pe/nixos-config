# Escritorio: Hyprland lanzado con UWSM, igual que en kadachi
{ pkgs, ... }:
{
  programs = {
    uwsm.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    # Crea el servicio PAM de hyprlock; sin él la pantalla bloqueada no acepta la contraseña
    hyprlock.enable = true;
    noctalia.enable = true;
  };
  # Sin la espera de 2 s de pam_unix tras fallar: en el bloqueo se puede reintentar al momento
  security.pam.services.hyprlock.nodelay = true;
  # Un suspend dejó colgada la NVIDIA al volver y se perdió la sesión. Además Docker/fine-tuning no deben parar:
  # la tecla de suspender solo bloquea y el sistema no se suspende ni hiberna por ningún camino
  services.logind.settings.Login.HandleSuspendKey = "lock";
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Slack, Chrome, Obsidian… en Wayland nativo: nítidos con escalado y compartir pantalla funciona
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
  };
  # Donde tuigreet guarda el último usuario (--remember)
  systemd.tmpfiles.rules = [ "d /var/cache/tuigreet 0755 greeter greeter -" ];

  # Llavero de contraseñas (VPN, Chrome, Zed); se desbloquea al entrar por tuigreet
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  xdg.portal = {
    enable = true;
    config.common.default = "gtk";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # De kadachi (megurine/is/desktop): audio, montaje de USB y polkit
  security.polkit.enable = true;
  security.rtkit.enable = true; # prioridad realtime para PipeWire: sin cortes en llamadas
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
    devmon.enable = true; # monta los USB al conectarlos
  };
  hardware.bluetooth.enable = true;

  # De kadachi (adachi/hardware/i2c): brillo del monitor externo desde Noctalia
  hardware.i2c.enable = true;
  environment.systemPackages = [ pkgs.ddcutil ];

  # Impresoras de la oficina (IPP/mDNS)
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Syncthing (en modules/home/apps.nix) entre dispositivos de la misma red
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
