{ pkgs, user, ... }:
{
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker" # se aplica al iniciar sesión: tras el primer switch, reinicia (o `newgrp docker`)
      "i2c" # brillo del monitor externo por DDC
    ];
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  # De kadachi (kasane/zsh): autocompletado de los paquetes del sistema
  environment.pathsToLink = [ "/share/zsh" ];
}
