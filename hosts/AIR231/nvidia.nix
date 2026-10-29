# Solo para gráficas NVIDIA; se importa desde el default.nix del host
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # RTX 20xx o más nueva; para más antiguas pon false
    # Guarda la VRAM al suspender: sin esto, al volver la pantalla sale negra o con basura
    # y lo que hubiera cargado en la GPU (modelos de Ollama, CUDA) se rompe
    powerManagement.enable = true;
  };

  # GPU dentro de contenedores: docker run --device nvidia.com/gpu=all ...
  hardware.nvidia-container-toolkit.enable = true;

  # Hyprland sobre NVIDIA
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
