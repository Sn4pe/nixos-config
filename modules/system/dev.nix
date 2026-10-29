{
  # agentos levanta todo con `docker compose`
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    # Docker se salta el firewall: así los puertos publicados (Postgres, Mongo, Redis…)
    # solo escuchan en este PC y no en la red de la oficina ni en la VPN
    daemon.settings = {
      ip = "127.0.0.1";
      # Imágenes, volúmenes y caché de build en el NVMe de datos (~40 GB), no en el del sistema
      data-root = "/data/docker";
    };
  };
  # Sin /data montado, que no arranque (si no, empezaría de cero en el disco del sistema)
  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/data/docker" ];

  # Redis (en el compose de agentos) lo pide en su log; de kadachi (hosts/mizuki)
  boot.kernel.sysctl."vm.overcommit_memory" = 1;
}
