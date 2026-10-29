# Tailscale (tailnet personal): llegar a este PC desde fuera y a las otras máquinas.
# El login es una vez y a mano: `sudo tailscale up --accept-routes`. Nada de esto va a secrets:
# la identidad del equipo la guarda Tailscale en /var/lib/tailscale, fuera del repo
{ user, ... }:
{
  services.tailscale = {
    enable = true;
    # Operador: tu usuario controla Tailscale sin sudo (lo usa el plugin Tailnet de Noctalia)
    extraSetFlags = [ "--operator=${user}" ];
    openFirewall = true; # UDP 41641: conexión directa en vez de por los relés
    useRoutingFeatures = "client"; # para usar las rutas que anuncien otras máquinas
  };
  # Sin trustedInterfaces: cada servicio abre su puerto solo en tailscale0 (ver hosts/AIR231/ollama.nix)
}
