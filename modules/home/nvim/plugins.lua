-- Theme: "auto" elige latte o mocha según 'background', que fija neovim.nix con la polarity de Stylix
require("catppuccin").setup({
  flavour = "auto",
  background = { light = "latte", dark = "mocha" },
  no_italic = true,
  -- kitty ya tiene opacidad (stylix.opacity.terminal)
  transparent_background = true,
  float = {
    transparent = true,
  },
})
vim.cmd.colorscheme("catppuccin")

require("mini.icons").setup({})

-- UI
local function show_macro_recording()
  local recording_register = vim.fn.reg_recording()
  if recording_register ~= "" then
    return " REC @" .. recording_register
  end
  return ""
end

require("lualine").setup({
  options = {
    theme = "catppuccin-nvim",
    component_separators = "",
    section_separators = "",
    refresh = {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "SessionLoadPost",
        "FileChangedShellPost",
        "VimResized",
        "Filetype",
        "CursorMoved",
        "CursorMovedI",
        "ModeChanged",
        "RecordingEnter",
        "RecordingLeave",
      },
    },
  },
  sections = {
    lualine_x = { show_macro_recording },
    lualine_y = {},
  },
})

-- fzf-lua
local fzf_lua = require("fzf-lua")
fzf_lua.setup()
fzf_lua.register_ui_select()

vim.keymap.set({ "n" }, "<leader>bb", fzf_lua.buffers)
vim.keymap.set({ "n" }, "<leader>ca", function()
  fzf_lua.lsp_code_actions({
    filter = function(code_action, _)
      return not code_action.disabled
    end,
    previewer = "none",
  })
end)
vim.keymap.set({ "n" }, "<leader>dg", function()
  fzf_lua.diagnostics_document({
    multiline = 1,
    previewer = "none",
  })
end)
vim.keymap.set({ "n" }, "<leader>ff", fzf_lua.files)
vim.keymap.set({ "n" }, "<leader>fg", fzf_lua.live_grep)

-- Oil
require("oil").setup()
vim.keymap.set({ "n" }, "<leader>fe", "<cmd>Oil --float<CR>")

-- grug-far
local grug_far = require("grug-far")
grug_far.setup({})
vim.keymap.set({ "n" }, "<leader>fr", function()
  grug_far.open({ transient = true })
end)

-- inc-rename
require("inc_rename").setup({})
vim.keymap.set({ "n" }, "<leader>rn", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { desc = "Incremental rename", expr = true })
vim.keymap.set({ "n" }, "<leader>rr", ":IncRename ", { desc = "Incremental rename (clearing existing word)" })

-- Snippets and completion
require("luasnip.loaders.from_vscode").lazy_load()

require("blink.cmp").setup({
  keymap = {
    ["<c-space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
    ["<C-c>"] = { "hide" },
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<s-tab>"] = { "select_prev", "snippet_backward", "fallback" },
    ["<c-j>"] = { "scroll_documentation_down", "fallback" },
    ["<c-k>"] = { "scroll_documentation_up", "fallback" },
  },
  snippets = {
    preset = "luasnip",
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      snippets = {
        score_offset = 1,
      },
    },
  },
})

-- Formatting
require("conform").setup({
  formatters = {
    -- Solo en proyectos con config de prettier, para no reformatear repos que no lo usan
    prettier = { require_cwd = true },
  },
  formatters_by_ft = {
    bash = { "shfmt" },
    javascript = { "prettier" },
    lua = { "stylua" },
    nix = { "nixfmt" },
    python = { "ruff_format" },
    sh = { "shfmt" },
    svelte = { "prettier" },
    typescript = { "prettier" },
    vue = { "prettier" },
  },
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})

-- Autopairs
local autopairs = require("nvim-autopairs")
local Rule = require("nvim-autopairs.rule")
local cond = require("nvim-autopairs.conds")
local autopairs_utils = require("nvim-autopairs.utils")

autopairs.setup({})

-- Generics
autopairs.add_rule(Rule("<", ">"):with_pair(cond.before_regex("%a+:?:?$", 3)):with_move(function(opts)
  return opts.char == ">"
end))

-- Nix: semicolon after equals sign

-- Note that when the cursor is at the end of a comment line,
-- treesitter thinks we are in attrset_expression
-- because the cursor is "after" the comment, even though it is on the same line.
local is_not_ts_node_comment_one_back = function()
  return function(info)
    local p = vim.api.nvim_win_get_cursor(0)
    -- Subtract one to account for 1-based row indexing in nvim_win_get_cursor
    -- Also subtract one from the position of the column to see if we are at the end of a comment.
    local pos_adjusted = { p[1] - 1, p[2] - 1 }

    vim.treesitter.get_parser():parse()
    local target = vim.treesitter.get_node({ pos = pos_adjusted, ignore_injections = false })
    if target ~= nil and autopairs_utils.is_in_table({ "comment" }, target:type()) then
      return false
    end

    local rest_of_line = info.line:sub(info.col)
    return rest_of_line:match("^%s*$") ~= nil
  end
end

autopairs.add_rule(Rule("= ", ";", "nix"):with_pair(is_not_ts_node_comment_one_back()):set_end_pair_length(1))

-- Spider: w, e, b y ge por subpalabras (camelCase, snake_case)
local spider = require("spider")
spider.setup({ subwordMovement = true })

for _, motion in ipairs({ "w", "e", "b", "ge" }) do
  vim.keymap.set({ "n", "o", "x" }, motion, function()
    spider.motion(motion)
  end)
end
