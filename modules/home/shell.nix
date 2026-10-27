# Terminal: kitty + zsh (de kadachi, kasane/zsh, sin el modo vim) + starship
{ config, ... }:
{
  programs = {
    kitty = {
      enable = true;
      settings = {
        enable_audio_bell = "no";
        window_padding_width = 8;
        scrollback_lines = 8000;
      };
    };

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      history.path = "${config.xdg.dataHome}/zhistory";
      syntaxHighlighting.enable = true;
      initContent = ''
        setopt AUTO_PUSHD SHARE_HISTORY MENUCOMPLETE
        autoload -U history-search-end
        zle -N history-beginning-search-backward-end history-search-end
        zle -N history-beginning-search-forward-end history-search-end
        bindkey "^[OA" history-beginning-search-backward-end
        bindkey "^[OB" history-beginning-search-forward-end
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      '';
      shellAliases = {
        rbd = "nh os switch";
        tema-claro = "sudo /nix/var/nix/profiles/system/specialisation/claro/bin/switch-to-configuration test";
        tema-oscuro = "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test";
      };
    };

    starship.enable = true;
  };
}
