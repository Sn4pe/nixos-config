# Animaciones más rápidas que las de serie (abrir ventana ~0,2 s en vez de ~0,4 s).
# speed = duración en décimas de segundo: más bajo, más rápido
{
  wayland.windowManager.hyprland.extraLuaFiles.animations = ''
    hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
    hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1} } })
    hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
    hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

    hl.animation({ leaf = "windows",    enabled = true, speed = 2.5, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2,   bezier = "easeOutQuint", style = "popin 87%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "linear",       style = "popin 87%" })
    hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1.2, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1,   bezier = "almostLinear" })
    hl.animation({ leaf = "fade",       enabled = true, speed = 1.5, bezier = "quick" })
    hl.animation({ leaf = "layers",     enabled = true, speed = 2,   bezier = "easeOutQuint" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })
  '';
}
