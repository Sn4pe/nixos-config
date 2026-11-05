# hyprglance (github.com/Sn4pe/hyprglance): selector de ventanas con Super+Tab y vista general con F3
{ config, ... }:
{
  programs.hyprglance.enable = true;

  wayland.windowManager.hyprland.extraLuaFiles.hyprglance = ''
    dofile("${config.programs.hyprglance.luaModule}").setup()
  '';
}
