# De kadachi (kasane/desktop/noctalia): barra a la izquierda, notificaciones, lanzador y menú de apagado
{ osConfig, ... }:
let
  ipc = "noctalia msg";
in
{
  programs.noctalia = {
    enable = true;
    settings = {
      audio.enable_sounds = false;

      bar.default = {
        enabled = true;
        position = "left";
        background_opacity = osConfig.stylix.opacity.terminal;
        margin_edge = 8;
        margin_ends = 8;
        start = [
          "launcher"
          "workspaces"
        ];
        center = [ ];
        end = [
          "tray"
          "bluetooth"
          "volume"
          "clock"
        ];
      };

      theme.builtin = "Catppuccin";

      notification.layer = "overlay";

      osd = {
        enabled = true;
        position = "bottom_center";
      };

      shell.polkit_agent = true;

      wallpaper.enabled = false; # el fondo lo pone awww

      widget.clock.format = "{:%H:%M}";
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [ "noctalia" ];
    bind = [
      "SUPER, D, exec, ${ipc} panel-toggle launcher"
      "SUPER, Space, exec, ${ipc} panel-toggle launcher"
      "CTRL ALT, Delete, exec, ${ipc} panel-toggle session"
    ];
    bindle = [
      ", XF86MonBrightnessUp, exec, ${ipc} brightness-up"
      ", XF86MonBrightnessDown, exec, ${ipc} brightness-down"
    ];
  };
}
