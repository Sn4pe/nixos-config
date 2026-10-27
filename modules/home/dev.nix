{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_24 # agentos pide >= 22; sus Dockerfiles usan node:22
    protobuf
    claude-code
    gh
  ];

  programs = {
    git = {
      enable = true;
      settings.user.email = "dfadon@air-institute.com";
      # Para no subir por error el .envrc a repos que no son tuyos (agentos)
      ignores = [
        ".envrc"
        ".direnv/"
      ];
    };
    # Al entrar en una carpeta con .envrc carga su shell de Nix (ver shells/)
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
