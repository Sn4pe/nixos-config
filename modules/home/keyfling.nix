# KeyFling (github.com/Sn4pe/keyfling): host nativo para Chrome, Firefox y LibreWolf.
# La extensión se carga a mano desde ~/Projects/keyfling/dist/production/{chrome,firefox}
{ config, lib, pkgs, ... }:
let
  repo = "${config.home.homeDirectory}/Projects/keyfling";

  # El adaptador de Claude usa el binario de Nix, no el que trae el SDK de npm
  host = pkgs.writeShellScript "keyfling-host" ''
    export CLAUDE_CODE_EXECUTABLE=${lib.getExe config.programs.claude-code.package}
    exec ${pkgs.nodejs_24}/bin/node ${repo}/host/keyfling-host.js "$@"
  '';

  manifest =
    allowed:
    builtins.toJSON (
      {
        name = "com.keyfling.host";
        description = "KeyFling native host";
        path = "${host}";
        type = "stdio";
      }
      // allowed
    );

  # Firefox y LibreWolf usan el ID fijo del complemento (config/webpack.config.js del repo)
  gecko = manifest { allowed_extensions = [ "keyfling@sn4pe" ]; };
in
{
  home.file = {
    # ID fijo por la clave "key" del manifest de la extensión
    ".config/google-chrome/NativeMessagingHosts/com.keyfling.host.json".text = manifest {
      allowed_origins = [ "chrome-extension://ijeigbclmiimeifflpecplahaodajcho/" ];
    };
    ".mozilla/native-messaging-hosts/com.keyfling.host.json".text = gecko;
    ".librewolf/native-messaging-hosts/com.keyfling.host.json".text = gecko;
  };
}
