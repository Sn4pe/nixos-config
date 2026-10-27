# VPN de AIR con NetworkManager. El .ovpn es personal: no va al repo, se importa a mano una vez
# (ver README). Luego se conecta desde el icono de red de la bandeja o con `nmcli connection up <nombre>`
{ pkgs, ... }:
{
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # Icono de red en la bandeja de Noctalia; también pide la contraseña de la VPN si hace falta
  programs.nm-applet.enable = true;
}
