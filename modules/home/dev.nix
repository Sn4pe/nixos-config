{ lib, pkgs, ... }:
let
  # programs.git.hooks fija un core.hooksPath global que tapa .git/hooks de cada repo:
  # cada hook de aquí ejecuta también el del repo, si lo tiene
  repoHook = name: ''
    repo_hook="$(git rev-parse --git-common-dir)/hooks/${name}"
    if [ -x "$repo_hook" ]; then "$repo_hook" "$@" || exit $?; fi
  '';
  hookNames = [
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "pre-commit"
    "pre-merge-commit"
    "prepare-commit-msg"
    "post-commit"
    "pre-rebase"
    "post-checkout"
    "post-merge"
    "pre-push"
    "post-rewrite"
    "pre-auto-gc"
    "reference-transaction"
    "push-to-checkout"
    "post-index-change"
    "sendemail-validate"
  ];
  # Quita la atribución de IA (Co-Authored-By de Claude, "Generated with Claude Code"),
  # también en los commits que no hace Claude
  commitMsg = pkgs.writeShellScript "git-commit-msg" ''
    ${lib.getExe pkgs.gnused} -i -E '/^co-authored-by:.*(claude|anthropic)/Id; /generated with \[?claude code/Id' "$1"
    ${repoHook "commit-msg"}
  '';
in
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
      hooks = {
        commit-msg = commitMsg;
      }
      // lib.genAttrs hookNames (name: pkgs.writeShellScript "git-${name}" (repoHook name));
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
