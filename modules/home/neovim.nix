# De kadachi-nvim (git.rcia.dev/Avery/kadachi-nvim) con programs.neovim en vez de su wrapNeovim.
# La config Lua está en ./nvim, sin lz.n: todo carga al arrancar
{ config, pkgs, ... }:
{
  # El catppuccin-nvim de verdad pinta mejor que el base16 de Stylix, y sigue latte/mocha por 'background'
  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (
        p: with p; [
          bash
          comment
          css
          csv
          diff
          dockerfile
          git_rebase
          gitattributes
          gitcommit
          gitignore
          graphql
          html
          javascript
          jsdoc
          json
          lua
          luadoc
          markdown
          markdown_inline
          nix
          python
          query
          regex
          requirements
          rust
          sql
          svelte
          toml
          typescript
          vue
          yaml
        ]
      ))
      nvim-lspconfig
      blink-cmp
      luasnip
      friendly-snippets
      conform-nvim
      fzf-lua
      oil-nvim
      grug-far-nvim
      inc-rename-nvim
      nvim-autopairs
      nvim-spider
      gitsigns-nvim
      mini-diff
      codediff-nvim
      lualine-nvim
      mini-icons
      catppuccin-nvim
      obsidian-nvim
    ];

    extraPackages = with pkgs; [
      # LSPs
      basedpyright
      lua-language-server
      nil
      ruff
      rust-analyzer
      svelte-language-server
      typescript-language-server
      vue-language-server

      # Formatters
      nixfmt
      prettier
      shfmt
      stylua

      fzf
      ripgrep
    ];

    # nvim pregunta el fondo a la terminal y la de herdr no contesta: lo fija la polarity de Stylix
    initLua = ''
      vim.o.background = "${config.stylix.polarity}"
      vim.g.vue_language_server = "${pkgs.vue-language-server}/lib/language-tools/packages/language-server"
      require("config")
    '';
  };

  xdg.configFile."nvim/lua/config".source = ./nvim;
}
