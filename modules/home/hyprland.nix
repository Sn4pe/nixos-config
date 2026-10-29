# De kadachi (kasane/desktop/hyprland + kasane/theme), con teclado es en vez de dvorak
# Config en Lua (hyprlang está obsoleto desde 0.55): opciones, monitores y escritorios como
# atributos de Nix (hl.config/hl.monitor/hl.workspace_rule); binds y autoarranque en .lua
{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cursor = osConfig.stylix.cursor;

  # En Lua, `hyprctl dispatch` espera un dispatcher de Lua; en script para no pelear con las comillas en hypridle.conf.
  # Si responde otra cosa (sesión hyprlang aún abierta tras el switch), usa la sintaxis antigua
  dpms =
    action:
    let
      legacy = if action == "enable" then "on" else "off";
    in
    pkgs.writeShellScript "hypr-dpms-${action}" ''
      hyprctl dispatch 'hl.dsp.dpms({ action = "${action}" })' | grep -q '^ok' || hyprctl dispatch dpms ${legacy}
    '';

  # Los dos MSI son iguales: se distinguen por el número de serie, no por el puerto HDMI
  # (así no se intercambian si cambias los cables). Ver `hyprctl monitors`
  left = "desc:Microstep MSI MP273A PB4H603502628";
  right = "desc:Microstep MSI MP273A PB4H603502614";

  # Fondos por modo: cada subcarpeta de assets/wallpapers es un modo, y `todos` las mezcla
  wallpapers = ../../assets/wallpapers;
  modes = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir wallpapers));
  modeFile = ''"''${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-mode"'';

  # Un fondo al azar del modo activo en cada monitor
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper-rotate";
    runtimeInputs = with pkgs; [
      awww
      jq
      findutils
      coreutils
      osConfig.programs.hyprland.package
    ];
    text = ''
      mode=$(cat ${modeFile} 2>/dev/null || echo todos)
      dir=${wallpapers}/$mode
      [ "$mode" != todos ] && [ -d "$dir" ] || dir=${wallpapers}
      # Al iniciar sesión awww-daemon puede no estar listo todavía
      for _ in $(seq 20); do awww query >/dev/null 2>&1 && break; sleep 0.5; done
      for out in $(hyprctl monitors -j | jq -r '.[].name'); do
        img=$(find "$dir" -type f -iname '*.jpg' | shuf -n 1)
        awww img -o "$out" --transition-type fade "$img"
      done
    '';
  };

  # `wallpaper-mode` dice el modo activo; `wallpaper-mode ascii` lo cambia y aplica al momento
  wallpaperMode = pkgs.writeShellApplication {
    name = "wallpaper-mode";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ $# -eq 0 ]; then
        cat ${modeFile} 2>/dev/null || echo todos
        exit
      fi
      case "$1" in
        todos | ${lib.concatStringsSep " | " modes}) ;;
        *)
          echo "Modo desconocido: $1. Disponibles: todos ${toString modes}" >&2
          exit 1
          ;;
      esac
      mkdir -p "$(dirname ${modeFile})"
      echo "$1" > ${modeFile}
      ${wallpaper}/bin/wallpaper-rotate
    '';
  };

  # Textos e imagen de la pantalla de bloqueo: `lock-info title|artist|cover|claude`.
  # Sin nada sonando, los textos salen vacíos y la carátula es un PNG transparente
  noCover = pkgs.runCommand "lock-no-cover.png" { } ''
    ${lib.getExe' pkgs.imagemagick "magick"} -size 1x1 xc:none $out
  '';
  # Tarjeta de la música: mismo oscuro translúcido que el campo de contraseña. Es una imagen (y no
  # un shape) para poder ocultarla cuando no suena nada
  musicCard = pkgs.runCommand "lock-music-card.png" { } ''
    ${lib.getExe' pkgs.imagemagick "magick"} -size 560x168 xc:none -fill "rgba(0,0,0,0.4)" \
      -draw "roundrectangle 0,0 559,167 24,24" $out
  '';
  lockInfo = pkgs.writeShellApplication {
    name = "lock-info";
    runtimeInputs = with pkgs; [
      playerctl
      curl
      jq
      coreutils
      gnused
    ];
    text = ''
      # Los labels de hyprlock son markup de Pango: & y < romperían el texto
      escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
      # Corta a N caracteres con … para que no se salga de la tarjeta
      trunc() {
        local v
        v=$(cat)
        if [ "''${#v}" -gt "$1" ]; then printf '%s…' "''${v:0:$(($1 - 1))}"; else printf '%s' "$v"; fi
      }
      meta() { playerctl --player=spotify,%any metadata "$1" 2>/dev/null || true; }
      playing() { [ -n "$(playerctl --player=spotify,%any status 2>/dev/null || true)" ]; }

      case "''${1:-}" in
        title) playing && meta title | trunc 22 | escape ;;
        artist) playing && meta artist | trunc 30 | escape ;;
        card) if playing; then echo ${musicCard}; else echo ${noCover}; fi ;;
        cover)
          url=$(playing && meta mpris:artUrl || true)
          case "$url" in
            http*)
              # Spotify da una URL: se descarga una vez por carátula
              f="''${XDG_RUNTIME_DIR:-/tmp}/lock-cover-$(printf '%s' "$url" | md5sum | cut -c1-12).jpg"
              [ -s "$f" ] || curl -sfL --max-time 3 -o "$f" "$url" || rm -f "$f"
              if [ -s "$f" ]; then echo "$f"; else echo ${noCover}; fi
              ;;
            file://*) echo "''${url#file://}" ;;
            *) echo ${noCover} ;;
          esac
          ;;
        claude)
          # Lo que guarda el plugin claudecode de Noctalia; si tiene más de 10 min, no se enseña
          f="$HOME/.claude/usage-cache.json"
          [ -f "$f" ] && [ $(( $(date +%s) - $(stat -c %Y "$f") )) -lt 600 ] || exit 0
          jq -r '.data | "Claude  \(.five_hour.utilization | floor)% · semana \(.seven_day.utilization | floor)%"' "$f" 2>/dev/null || true
          ;;
        *)
          echo "Usage: lock-info title|artist|cover|card|claude" >&2
          exit 1
          ;;
      esac
    '';
  };

  # Bloquea y pausa lo que esté sonando; al desbloquear reanuda solo lo que estaba sonando
  lock = pkgs.writeShellApplication {
    name = "lock-and-pause";
    runtimeInputs = [
      pkgs.playerctl
      config.programs.hyprlock.package
    ];
    text = ''
      playing=()
      while read -r p; do
        [ "$(playerctl -p "$p" status 2>/dev/null || true)" = Playing ] && playing+=("$p")
      done < <(playerctl -l 2>/dev/null || true)
      for p in "''${playing[@]}"; do playerctl -p "$p" pause || true; done
      hyprlock || true
      for p in "''${playing[@]}"; do playerctl -p "$p" play || true; done
    '';
  };
in
{
  home.packages = with pkgs; [
    awww
    grim
    slurp
    satty # anotar capturas (lo más parecido a ShareX, que solo existe en Windows)
    wallpaperMode
  ];

  # Pantalla de bloqueo: fondo nítido algo oscurecido en los dos monitores.
  # Izquierdo: una columna abajo a la izquierda (hora, fecha, contraseña y uso de Claude) con un
  # solo margen. Derecho: lo que suena, en una tarjeta con la carátula y el texto a su altura.
  # Texto en blanco con sombra corta: se lee sobre cualquier fondo y en tema claro u oscuro
  programs.hyprlock = {
    enable = true;
    settings =
      let
        margin = 72;
        text = {
          color = "rgba(255, 255, 255, 0.96)";
          font_family = "Noto Sans";
          shadow_passes = 3;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.6)";
        };
        column =
          y: extra:
          text
          // {
            monitor = left;
            halign = "left";
            valign = "bottom";
            position = "${toString margin}, ${toString y}";
          }
          // extra;
        cover = 128;
        pad = 20; # dentro de la tarjeta
        media =
          y: extra:
          text
          // {
            monitor = right;
            halign = "right";
            valign = "bottom";
            text_align = "right";
            position = "-${toString (margin + pad + cover + 24)}, ${toString y}";
            zindex = 2;
          }
          // extra;
        info = cmd: "cmd[update:2000] ${lib.getExe lockInfo} ${cmd}";
      in
      {
        background.brightness = 0.7;
        # Tras fallar, el aviso dura medio segundo y se puede volver a escribir enseguida
        general.fail_timeout = 500;
        image = [
          {
            monitor = right;
            halign = "right";
            valign = "bottom";
            position = "-${toString margin}, ${toString margin}";
            size = 168; # hyprlock escala por el lado corto: el alto de musicCard
            rounding = 0; # ya viene redondeada
            border_size = 0;
            path = "${noCover}";
            reload_time = 2;
            reload_cmd = "${lib.getExe lockInfo} card";
            zindex = 1;
          }
          {
            monitor = right;
            halign = "right";
            valign = "bottom";
            position = "-${toString (margin + pad)}, ${toString (margin + pad)}";
            size = cover;
            rounding = 12; # como las ventanas
            border_size = 0;
            path = "${noCover}";
            reload_time = 2;
            reload_cmd = "${lib.getExe lockInfo} cover";
            zindex = 2;
          }
        ];
        label = [
          # El "1" de la fuente tiene margen lateral: se corrige para alinear con lo de debajo
          (column 236 {
            position = "${toString (margin - 10)}, 236";
            text = "$TIME";
            font_family = "Noto Sans Light";
            font_size = 112;
          })
          (column 196 {
            text = ''cmd[update:60000] date "+%A, %-d de %B"'';
            font_size = 22;
            color = "rgba(255, 255, 255, 0.85)";
          })
          (column margin {
            text = info "claude";
            font_size = 13;
            color = "rgba(255, 255, 255, 0.7)";
          })
          # Título y artista juntos, centrados en vertical con la carátula
          (media (margin + pad + cover / 2 + 2) {
            text = info "title";
            font_family = "Noto Sans SemiBold";
            font_size = 22;
          })
          (media (margin + pad + cover / 2 - 32) {
            text = info "artist";
            font_size = 17;
            color = "rgba(255, 255, 255, 0.9)";
          })
        ];
        input-field = {
          monitor = left;
          halign = "left";
          valign = "bottom";
          position = "${toString margin}, 116";
          size = "320, 52";
          rounding = 12;
          outline_thickness = 0;
          # Oscuro translúcido en vez del bloque blanco de Stylix: no tapa el fondo
          inner_color = lib.mkForce "rgba(0, 0, 0, 0.4)";
          font_color = lib.mkForce "rgb(255, 255, 255)";
          dots_size = 0.22;
          dots_spacing = 0.35;
          dots_center = false;
          fade_on_empty = false;
          # La distribución de teclado, en tenue mientras está vacío
          placeholder_text = ''<span foreground="##ffffff88">$LAYOUT[ES]</span>'';
          # Con Bloq Mayús el campo se tiñe de naranja; al fallar, el error y los intentos
          capslock_color = "rgba(254, 100, 11, 0.55)";
          fail_text = "$FAIL ($ATTEMPTS)";
        };
      };
  };

  # Bloquea a los 10 min y apaga la pantalla a los 15; sin suspender (Docker/fine-tuning)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${lib.getExe lock}";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${dpms "enable"}";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "${dpms "disable"}";
          on-resume = "${dpms "enable"}";
        }
      ];
    };
  };

  # Cambia el fondo al entrar en la sesión y cada 30 min, dentro del modo de `wallpaper-mode`
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Fondo de pantalla al azar";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaper}/bin/wallpaper-rotate";
    };
  };
  systemd.user.timers.wallpaper-rotate = {
    Unit.PartOf = [ "graphical-session.target" ];
    Timer = {
      OnActiveSec = "2s";
      OnUnitActiveSec = "30min";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Historial del portapapeles; se abre con Super+Shift+V
  services.cliphist.enable = true;
  programs.fuzzel.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # El paquete lo pone el módulo de NixOS; UWSM se encarga de la sesión
    package = null;
    portalPackage = null;
    systemd.enable = false;

    settings = {
      # Monitor automático. Para fijarlo: { output = "DP-1"; mode = "2560x1440@165"; position = "0x0"; scale = 1; }
      # Monitor 4K: scale = 1.5 y config.xwayland.force_zero_scaling = true
      # Los dos MSI a izquierda y derecha, como están en la mesa; cualquier otro, en automático
      monitor = [
        {
          output = left;
          mode = "1920x1080@100"; # preferred da 60 Hz en estos MSI
          position = "0x0";
          scale = 1;
        }
        {
          output = right;
          mode = "1920x1080@100";
          position = "1920x0";
          scale = 1;
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        }
      ];

      # Los 10 escritorios siempre visibles en la barra: 1-5 a la izquierda, 6-10 a la derecha
      workspace_rule = builtins.genList (i: {
        workspace = toString (i + 1);
        monitor = if i < 5 then left else right;
        persistent = true;
        default = i == 0 || i == 5;
      }) 10;

      # Apps con escritorio fijo: Slack en el 6 (derecha), Spotify en el 10
      window_rule = [
        {
          match.class = "^(slack)$";
          workspace = "6";
        }
        {
          match.class = "^(spotify)$";
          workspace = "10";
        }
      ];

      config = {
        input = {
          kb_layout = "es";
          accel_profile = "flat";
        };

        # Huecos, desenfoque y bordes redondeados
        general = {
          gaps_in = 4;
          gaps_out = 8;
        };
        decoration = {
          rounding = 12;
          blur = {
            enabled = true;
            size = 2;
            passes = 3;
          };
          dim_inactive = true;
          dim_strength = 0.4;
          shadow.enabled = false;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          middle_click_paste = false;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };
    };

    extraLuaFiles = {
      # Las apps se lanzan con `uwsm app --` para que cada una tenga su propio servicio
      autostart = ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("hyprctl setcursor ${cursor.name} ${toString cursor.size}")
          hl.exec_cmd("uwsm app -- awww-daemon")
        end)
      '';

      binds = ''
        hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
        hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- pcmanfm-qt"))
        hl.bind("SUPER + B", hl.dsp.exec_cmd("uwsm app -- firefox"))
        hl.bind("SUPER + Q", hl.dsp.window.close())
        hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
        -- Al hacerla flotante conserva el tamaño del mosaico y parece que no pasa nada:
        -- la deja al 60 % x 70 % del monitor y centrada
        hl.bind("SUPER + V", function()
          hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
          local w = hl.get_active_window()
          local m = hl.get_active_monitor()
          if w and w.floating and m then
            hl.dispatch(hl.dsp.window.resize({ x = math.floor(m.width * 0.6), y = math.floor(m.height * 0.7) }))
            hl.dispatch(hl.dsp.window.center())
          end
        end)
        hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
        hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))
        hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

        -- Captura de zona / pantalla completa → satty para anotar, copiar o guardar
        hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename - --copy-command wl-copy --early-exit]]))
        hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | satty --filename - --copy-command wl-copy --early-exit"))

        hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
        hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
        hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
        hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

        -- Super+1…0 va al escritorio 1…10; con Shift mueve la ventana y la sigue
        for i = 1, 10 do
          local key = tostring(i % 10)
          local ws = tostring(i)
          hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = ws }))
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = true }))
        end

        -- Mover/redimensionar con SUPER + ratón y teclas de volumen
        hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
      '';
    };
  };
}
