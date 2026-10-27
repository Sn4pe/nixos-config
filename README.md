# nixos-config

NixOS unstable + home-manager + Hyprland (UWSM) con Noctalia y Catppuccin, es_ES / Europe/Madrid.
Trozos sacados de [kadachi](https://git.rcia.dev/Avery/kadachi), marcados con `# De kadachi`.

```
flake.nix                 entradas, usuario (dfadon) y lista de máquinas
hosts/pc/                 lo propio de esta máquina
  default.nix             stateVersion e imports de hardware
  nvidia.nix              driver NVIDIA + GPU en Docker (desactivado)
  hardware-configuration.nix   lo genera el instalador; súbelo a git (las flakes lo necesitan)
modules/system/           sistema, común a todas las máquinas
  base.nix                arranque, red, idioma
  nix.nix                 flakes, nh, nix-ld
  users.nix               tu usuario y zsh
  desktop.nix             Hyprland, login, audio, Bluetooth
  theme.nix               Stylix: Catppuccin oscuro + claro
  dev.nix                 Docker
  vpn.nix                 OpenVPN para NetworkManager (VPN de AIR)
modules/home/             tu usuario (home-manager)
  apps.nix                Zed, Slack, Obsidian, Spotify, Chrome, utilidades, Syncthing
  dev.nix                 Node 24, protoc, psql, mongosh, redis-cli, ripgrep, fd, jq,
                          bat, eza, lazygit, lazydocker, git, direnv
  shell.nix               kitty, zsh, starship, alias
  hyprland.nix            atajos, monitor, fondo, decoración, capturas, portapapeles
  noctalia.nix            barra, lanzador, notificaciones
  firefox.nix             uBlock, Bitwarden, sin telemetría
  xdg.nix                 apps por defecto, carpetas en castellano
shells/                   entornos por proyecto (ml)
assets/                   fondo de pantalla
```

**Añadir algo**: busca el módulo que encaja, o crea uno nuevo y añádelo a los `imports`
del `default.nix` de su carpeta. **Otra máquina**: copia `hosts/pc` a `hosts/portatil`
y añade `nixosConfigurations.portatil = mkHost "portatil";` en `flake.nix`.

## Instalación

1. Arranca la ISO **gráfica** de NixOS e instala con el asistente. Usuario `dfadon`
   y hostname `pc` (o los que quieras, pero cámbialos en `flake.nix`). Escritorio: "No desktop".
2. Reinicia, entra por TTY y clona el repo en `~/nixos-config`:

   ```bash
   nix-shell -p git gh
   gh auth login
   gh repo clone Sn4pe/nixos-config ~/nixos-config && cd ~/nixos-config
   cp /etc/nixos/hardware-configuration.nix hosts/pc/
   grep stateVersion /etc/nixos/configuration.nix   # si no es 26.05, cámbialo en hosts/pc y modules/home
   nix-shell -p pciutils --run "lspci | grep -iE 'vga|3d'"   # ¿NVIDIA? descomenta nvidia.nix en hosts/pc
   git add -A                                        # las flakes solo ven archivos que git conoce
   sudo nixos-rebuild switch --flake .#pc --extra-experimental-features 'nix-command flakes'
   ```

   NVIDIA anterior a RTX 20xx: pon `open = false` en `hosts/pc/nvidia.nix`.

3. Reinicia (también hace falta para que `docker` funcione sin sudo). Sale tuigreet; al entrar arranca Hyprland.
4. Sube `flake.lock` y `hosts/pc/hardware-configuration.nix`:

   ```bash
   git add -A && git commit -m "chore: add lock and hardware config" && git push
   ```

### Comprobar el primer día

- `docker compose version`: si falla, añade `pkgs.docker-compose` a `modules/home/dev.nix`.
- Una llamada de prueba en Slack compartiendo pantalla.
- Gráfica Intel: para vídeo acelerado en el navegador, `hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];` en `hosts/pc/default.nix`.
- Si el icono de red (VPN) no sale en la bandeja: `systemctl --user restart nm-applet`.
- `gh auth login` y `ssh-keygen` para GitHub; git ya usa la sesión de `gh` para HTTPS.

A partir de ahí, después de cada cambio: `nh os switch` (no hace falta `sudo`).

## VPN de AIR

El `.ovpn` es personal y **no va al repo**. En el PC nuevo, una sola vez:

1. Cópialo desde Windows (`Documentos/AIRInstitute_David-Fadón_air-openvpn.ovpn`) con un USB.
2. Impórtalo y comprueba el nombre que le pone:

   ```bash
   nmcli connection import type openvpn file ~/Descargas/AIRInstitute_David-Fadón_air-openvpn.ovpn
   nmcli connection show
   ```

3. Bórralo de Descargas: NetworkManager ya guarda su copia.

Para conectar: icono de red en la bandeja de Noctalia, o `nmcli connection up <nombre>`.

## Shells por proyecto

Lo de uso diario va global en `modules/home/dev.nix` (Node 24 y protoc para agentos). Lo de
proyectos que tocas de vez en cuando vive en `shells/` y aparece solo dentro de su carpeta:

```bash
cd ~/proyectos/finetune
echo 'use flake ~/nixos-config#ml' > .envrc
direnv allow
```

Al entrar en la carpeta se carga solo; al salir, desaparece.
`.envrc` está en el gitignore global, así que no lo subirás a repos ajenos.

- **Proyecto nuevo**: copia `shells/ml.nix` con otro nombre y añádelo en `shells/default.nix`.
- **Algo puntual**, sin tocar nada: `nix shell nixpkgs#htop` o `nix develop ~/nixos-config#ml`.
- **Fine-tuning**: shell `ml` (Python 3.12 + uv). `uv pip install torch` funciona gracias a
  `nix-ld` y al `LD_LIBRARY_PATH` de la shell; con NVIDIA activa también `hosts/pc/nvidia.nix`.

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
| `Super + L` | Bloquear (también solo a los 10 min; pantalla apagada a los 15) |
| `Super + Shift + E` | Salir de Hyprland |
| `Impr Pant` / `Shift + Impr Pant` | Captura de zona / pantalla completa → satty (anotar, copiar, guardar) |
| `Super + Shift + V` | Historial del portapapeles |

## Pendiente para más adelante (está en kadachi)

- Tu nombre en git: `programs.git.settings.user.name` en `modules/home/dev.nix`.
- AutoFirma: `kasane/programs/autofirma.nix` (input `autofirma-nix`).
- Secure Boot (lanzaboote) y kernel CachyOS: mejor cuando el sistema ya arranque bien.
- Tema claro también en Noctalia: la specialisation `claro` solo cambia Stylix (GTK, Qt, kitty…);
  Noctalia se cambia desde su panel de ajustes.
