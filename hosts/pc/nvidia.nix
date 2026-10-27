# Solo para gráficas NVIDIA. Se activa descomentando su import en hosts/pc/default.nix
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # RTX 20xx o más nueva; para más antiguas pon false
  };

  # GPU dentro de contenedores: docker run --device nvidia.com/gpu=all ...
  hardware.nvidia-container-toolkit.enable = true;

  # Hyprland sobre NVIDIA
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
