# nixos-config

Flake mínima: NixOS unstable + home-manager + Hyprland (UWSM), es_ES / Europe/Madrid.
Trozos sacados de [kadachi](https://git.rcia.dev/Avery/kadachi), marcados con `# De kadachi`.

| Archivo | Qué hay |
|---|---|
| `flake.nix` | Entradas, nombre de usuario (`dfadon`) y hostname (`pc`) |
| `configuration.nix` | Sistema: arranque, red, idioma, audio, Hyprland, login (tuigreet) |
| `home.nix` | Tu usuario: Hyprland, waybar, kitty, fuzzel, Zed, Claude Code, Slack, Obsidian, Spotify, direnv |
| `shells.nix` | Entornos por proyecto ocasional (`ml`) |
| `nvidia.nix` | Driver NVIDIA + GPU en Docker. Desactivado: descomenta su línea en `flake.nix` |
| `hardware-configuration.nix` | **No está aquí**: lo genera el instalador en cada PC |

## Instalación

1. Arranca la ISO **gráfica** de NixOS e instala con el asistente. Usuario `dfadon`
   y hostname `pc` (o los que quieras, pero cámbialos en `flake.nix`). Escritorio: "No desktop".
2. Reinicia, entra por TTY y trae esta carpeta a `~/nixos-config` (git clone o USB):

   ```bash
   nix-shell -p git
   cd ~/nixos-config
   cp /etc/nixos/hardware-configuration.nix .
   grep stateVersion /etc/nixos/configuration.nix   # copia ese valor en configuration.nix y home.nix
   git init && git add -A                            # las flakes solo ven archivos que git conoce
   sudo nixos-rebuild switch --flake .#pc --extra-experimental-features 'nix-command flakes'
   ```

3. Reinicia. Sale tuigreet; al entrar arranca Hyprland.

A partir de ahí, después de cada cambio: `nh os switch` (no hace falta `sudo`).

## Shells por proyecto

Lo de uso diario va global en `home.nix` (Node 24 y protoc para agentos). Lo de
proyectos que tocas de vez en cuando vive en `shells.nix` y aparece solo dentro de su carpeta:

```bash
cd ~/proyectos/finetune
echo 'use flake ~/nixos-config#ml' > .envrc
direnv allow
```

Al entrar en la carpeta se carga solo; al salir, desaparece.
`.envrc` está en el gitignore global, así que no lo subirás a repos ajenos.

- **Proyecto nuevo**: copia un bloque en `shells.nix` con lo que necesite.
- **Algo puntual**, sin tocar nada: `nix shell nixpkgs#htop` o `nix develop ~/nixos-config#ml`.
- **Fine-tuning**: shell `ml` (Python 3.12 + uv). `uv pip install torch` funciona gracias a
  `nix-ld` y al `LD_LIBRARY_PATH` de la shell; con NVIDIA activa también `nvidia.nix`.

## Atajos

| Tecla | Acción |
|---|---|
| `Super + Enter` | Terminal (kitty) |
| `Super + D` / `Super + Espacio` | Lanzador (Noctalia) |
| `Super + E` | Archivos (pcmanfm-qt) |
| `Super + B` | Firefox |
| `Ctrl + Alt + Supr` | Menú apagar / reiniciar |
| `tema-claro` / `tema-oscuro` | Catppuccin Latte / Mocha (en la terminal) |
| `Super + Q` | Cerrar ventana |
| `Super + 1..0` / `+ Shift` | Ir a escritorio / mover ventana |
| `Super + L` | Bloquear |
| `Super + Shift + E` | Salir de Hyprland |
| `Impr Pant` | Captura de zona al portapapeles |

## Pendiente para más adelante (está en kadachi)

- Tu nombre en git: `programs.git.settings.user.name` en `home.nix`.
- AutoFirma: `kasane/programs/autofirma.nix` (input `autofirma-nix`).
- Secure Boot (lanzaboote) y kernel CachyOS: mejor cuando el sistema ya arranque bien.
