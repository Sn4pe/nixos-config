# Claude Desktop (beta oficial) empaquetado en pkgs/claude-desktop.
# No se actualiza solo: cada día se mira si Anthropic ha sacado versión nueva y, si la hay, sale una
# notificación. "Update" abre kitty con el diff y pregunta antes de aplicar; "Later" no toca nada.
# A mano: `claude-desktop-update` (o `systemctl --user start claude-desktop-check` para forzar el aviso)
{ lib, pkgs, ... }:
let
  repo = "/etc/nixos";
  updater = "${repo}/pkgs/claude-desktop/update.sh";

  # Los servicios de usuario arrancan con un PATH mínimo: sudo (para nh) y lo del sistema
  sessionPath = "/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin";

  updaterInputs = with pkgs; [
    bash
    coreutils
    curl
    gawk
    gnused
    perl
    nix
  ];

  update = pkgs.writeShellApplication {
    name = "claude-desktop-update";
    runtimeInputs = updaterInputs ++ [ pkgs.git ];
    text = ''
      export PATH="$PATH:${sessionPath}"
      cd ${repo}

      bash ${updater}
      echo
      git --no-pager diff --color -- pkgs/claude-desktop
      echo

      read -r -p "Apply now (nh os switch path:${repo})? [y/N] " answer
      if [[ "$answer" == [yY] ]]; then
        nh os switch path:${repo}
        echo
        echo "Done. Remember to commit: git -C ${repo} commit pkgs/claude-desktop"
      else
        echo "Not applied. The change stays in ${repo}; apply it later with rbd, or undo it with:"
        echo "  git -C ${repo} checkout pkgs/claude-desktop"
      fi
    '';
  };

  check = pkgs.writeShellApplication {
    name = "claude-desktop-check";
    runtimeInputs = updaterInputs ++ [
      pkgs.libnotify
      pkgs.kitty
    ];
    text = ''
      # Sin red o con el repo caído no avisa de nada; ya lo intentará mañana
      versions=$(bash ${updater} --check) || exit 0
      [[ -n "$versions" ]] || exit 0

      action=$(notify-send -a "Claude Desktop" -i claude-desktop \
        --action=update=Update --action=later=Later \
        "Claude Desktop update available" \
        "$versions<br>Changelog: https://code.claude.com/docs/en/desktop-linux")

      if [[ "$action" == update ]]; then
        exec kitty --title "Claude Desktop update" --hold ${lib.getExe update}
      fi
    '';
  };
in
{
  home.packages = [
    (pkgs.callPackage ../../pkgs/claude-desktop { })
    update
    check
  ];

  systemd.user = {
    services.claude-desktop-check = {
      Unit.Description = "Check for a new Claude Desktop version";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe check;
      };
    };
    timers.claude-desktop-check = {
      Unit.Description = "Check for a new Claude Desktop version daily";
      Timer = {
        OnCalendar = "daily";
        OnStartupSec = "10min"; # también poco después de iniciar sesión
        Persistent = true;
        RandomizedDelaySec = "30min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
