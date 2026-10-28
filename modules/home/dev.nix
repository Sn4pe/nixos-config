{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_24 # agentos pide >= 22; sus Dockerfiles usan node:22
    protobuf
    # Módulos nativos de npm (node-gyp)
    python3
    gcc
    gnumake
    # Clientes de lo que levanta el docker compose de agentos
    postgresql # psql
    mongosh
    redis # redis-cli
    xh # peticiones HTTP al api-gateway; de kadachi
    # Terminal
    ripgrep
    fd
    jq
    bat
    eza
    lazygit
    lazydocker
  ];

  programs = {
    # Instala claude-code y le registra los servidores MCP (plugin "hm")
    claude-code = {
      enable = true;
      mcpServers.nixos.command = lib.getExe pkgs.mcp-nixos;
    };
    git = {
      enable = true;
      settings = {
        user.email = "dfadon@air-institute.com";
        init.defaultBranch = "main";
        fetch.prune = true; # de kadachi (kasane/programs/git)
      };
      # Para no subir por error el .envrc a repos que no son tuyos (agentos)
      ignores = [
        ".envrc"
        ".direnv/"
      ];
    };
    # Tras `gh auth login`, git usa esa sesión para push/pull por HTTPS
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings.git_protocol = "https";
    };
    # De kadachi (defaults/ssh): la passphrase de la clave SSH se pide una vez por sesión
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".AddKeysToAgent = "yes";
    };
    # Al entrar en una carpeta con .envrc carga su shell de Nix (ver shells/)
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  services.ssh-agent.enable = true;
}
