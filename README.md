# nixos-config

NixOS unstable + home-manager + Hyprland (UWSM) con Noctalia y Catppuccin, es_ES / Europe/Madrid.
Trozos sacados de [kadachi](https://git.rcia.dev/Avery/kadachi), marcados con `# De kadachi`.

```
flake.nix                 entradas, usuario (dfadon) y lista de máquinas
hosts/AIR231/             lo propio de esta máquina (el hostname)
  default.nix             stateVersion e imports de hardware
  nvidia.nix              driver NVIDIA (RTX 4080) + GPU en Docker
  hardware-configuration.nix   lo genera el instalador; súbelo a git (las flakes lo necesitan)
modules/system/           sistema, común a todas las máquinas
  base.nix                arranque, red, idioma
  nix.nix                 flakes, nh, nix-ld
  users.nix               tu usuario y zsh
  desktop.nix             Hyprland, login, audio, Bluetooth
  theme.nix               Stylix: Catppuccin claro (Latte) + oscuro con `theme`
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
del `default.nix` de su carpeta. **Otra máquina**: copia `hosts/AIR231` a `hosts/portatil`
y añade `nixosConfigurations.portatil = mkHost "portatil";` en `flake.nix`.

## Instalación

1. Arranca la ISO **gráfica** de NixOS e instala con el asistente. Usuario `dfadon`
   y hostname `AIR231` (o los que quieras, pero cámbialos en `flake.nix`). Escritorio: "No desktop".
2. Reinicia, entra por TTY y clona el repo en `/etc/nixos` (a tu nombre, para no necesitar sudo):

   ```bash
   nix-shell -p git gh
   gh auth login
   sudo mv /etc/nixos /etc/nixos.orig && sudo install -d -o $USER /etc/nixos
   gh repo clone Sn4pe/nixos-config /etc/nixos && cd /etc/nixos
   cp /etc/nixos.orig/hardware-configuration.nix hosts/AIR231/
   grep stateVersion /etc/nixos.orig/configuration.nix   # si no es 26.05, cámbialo en hosts/AIR231 y modules/home
   nix-shell -p pciutils --run "lspci | grep -iE 'vga|3d'"   # ¿sin NVIDIA? quita nvidia.nix de hosts/AIR231
   git add -A                                        # las flakes solo ven archivos que git conoce
   gh auth setup-git                                 # git (y Nix) bajan el repo privado `secrets` con tu sesión
   # --sudo y no `sudo nixos-rebuild`: así evalúa tu usuario, que es quien tiene acceso al repo privado
   nixos-rebuild switch --flake .#AIR231 --sudo --extra-experimental-features 'nix-command flakes'
   ```

   Tras ese primer switch, git ya usa el `gh` de Home Manager; quita el del nix-shell, que desaparecerá:
   `git config --global --unset-all credential.https://github.com.helper`

   NVIDIA anterior a RTX 20xx: pon `open = false` en `hosts/AIR231/nvidia.nix`.

3. Reinicia (también hace falta para que `docker` funcione sin sudo). Sale tuigreet; al entrar arranca Hyprland.
4. Sube `flake.lock` y `hosts/AIR231/hardware-configuration.nix`:

   ```bash
   git add -A && git commit -m "chore: add lock and hardware config" && git push
   ```

### Comprobar el primer día

- `docker compose version`: si falla, añade `pkgs.docker-compose` a `modules/home/dev.nix`.
- Una llamada de prueba en Slack compartiendo pantalla.
- Gráfica Intel: para vídeo acelerado en el navegador, `hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];` en `hosts/AIR231/default.nix`.
- Si el icono de red (VPN) no sale en la bandeja: `systemctl --user restart nm-applet`.
- `gh auth login` y `ssh-keygen` para GitHub; git ya usa la sesión de `gh` para HTTPS.

A partir de ahí, después de cada cambio: `nh os switch` (no hace falta `sudo`).

## Repo privado (`secrets`)

Lo que no debe estar en este repo público vive en [sn4pe/nixos-secrets](https://github.com/sn4pe/nixos-secrets)
(privado), que entra como input `secrets` en `flake.nix`; igual que kadachi con `kadachi-secrets`.
Ahora mismo: el agente de inventario OCS de AIR (`AIR231/inventory.nix`). Nix lo descarga con tu
sesión de `gh`, así que haz `gh auth login` antes del primer `nixos-rebuild`.

Para cambiar algo de ahí:

```bash
cd ~/nixos-secrets && git commit -am "..." && git push
cd /etc/nixos && nix flake update secrets && nh os switch
```

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
echo 'use flake /etc/nixos#ml' > .envrc
direnv allow
```

Al entrar en la carpeta se carga solo; al salir, desaparece.
`.envrc` está en el gitignore global, así que no lo subirás a repos ajenos.

- **Proyecto nuevo**: copia `shells/ml.nix` con otro nombre y añádelo en `shells/default.nix`.
- **Algo puntual**, sin tocar nada: `nix shell nixpkgs#htop` o `nix develop /etc/nixos#ml`.
- **Fine-tuning**: shell `ml` (Python 3.12 + uv). `uv pip install torch` funciona gracias a
  `nix-ld` y al `LD_LIBRARY_PATH` de la shell; con NVIDIA activa también `hosts/AIR231/nvidia.nix`.

## Atajos

| Tecla | Acción |
|---|---|
| `Super + Enter` | Terminal (kitty) |
| `Super + D` / `Super + Espacio` | Lanzador (Noctalia) |
| `Super + E` | Archivos (pcmanfm-qt) |
| `Super + B` | Firefox |
| `Ctrl + Alt + Supr` | Menú apagar / reiniciar |
| `Super + Q` | Cerrar ventana |
| `Super + 1..0` / `+ Shift` | Ir a escritorio / mover ventana |
| `Super + L` | Bloquear (también solo a los 10 min; pantalla apagada a los 15) |
| `Super + Shift + E` | Salir de Hyprland |
| `Impr Pant` / `Shift + Impr Pant` | Captura de zona / pantalla completa → satty (anotar, copiar, guardar) |
| `Super + Shift + V` | Historial del portapapeles |
| `theme` | Cambiar tema claro / oscuro (también "Toggle theme" en el lanzador) |

## Pendiente para más adelante (está en kadachi)

- Tu nombre en git: `programs.git.settings.user.name` en `modules/home/dev.nix`.
- AutoFirma: `kasane/programs/autofirma.nix` (input `autofirma-nix`).
- Atajos tipo Mac (`Super` = `Cmd`): `Super+Tab`, `Super+W`, `Super+M/H` (ocultar), `Super+,` (ajustes de Noctalia),
  `Super+Alt+Esc` (forzar cierre), `Super+Ctrl+←/→` (escritorios), scroll natural; capturas con
  `Super+Shift+3/4` (habría que mover "mover ventana" a `Super+Alt+número`) y `Super+C/V` en kitty.
