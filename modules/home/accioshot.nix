# Capturas de pantalla. La bandeja arranca con la sesión; los atajos están en hyprland.nix
{ inputs, pkgs, ... }:
let
  accioshot = inputs.accioshot.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ accioshot ];

  systemd.user.services.accioshot = {
    Unit = {
      Description = "Bandeja de accioshot";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${accioshot}/bin/accioshot daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
