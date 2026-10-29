# Segundo NVMe (Samsung 980 PRO, serie S5GXNF0W607639T) en /data: modelos de Ollama, datasets y
# checkpoints, fuera del disco del sistema. Formateado a mano una vez con la etiqueta `data` (ver README)
{
  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    # nofail: si el disco falta, el sistema arranca igual (Ollama no, ver ollama.nix)
    options = [
      "noatime"
      "compress=zstd"
      "nofail"
    ];
  };
}
