# Modelos locales en la RTX 4080 con Ollama: API en http://127.0.0.1:11434 (`ollama run qwen3:8b`)
# y desde la tailnet en http://<nombre-del-pc>:11434
{ config, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0"; # el firewall solo deja pasar desde Tailscale, no desde la red local
    # Modelos en el NVMe de datos. Con usuario fijo: el dinámico no puede ser dueño de una carpeta fuera de /var/lib
    modelsDir = "/data/ollama/models";
    user = "ollama";
    group = "ollama";
    # Caché de contexto en q8 (la mitad de VRAM que f16): más contexto y gemma4 entero en los 16 GB
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };
  systemd.tmpfiles.rules = [ "d /data/ollama/models 0755 ollama ollama -" ];
  # Sin el disco de datos montado, que no arranque (si no, descargaría los modelos en el disco del sistema)
  systemd.services.ollama.unitConfig.RequiresMountsFor = [ "/data/ollama/models" ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.ollama.port ];

  # Lo de CUDA no está en cache.nixos.org (no es libre); sin esta caché, ollama-cuda se compila en local
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
  };
}
