-- Los vaults salen de la config de la app de Obsidian: sin ninguno abierto allí, no se carga
local config_path = vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config"
local obsidian_config_file = config_path .. "/obsidian/obsidian.json"

if not vim.uv.fs_stat(obsidian_config_file) then
  return
end

local workspaces = {}
for _, vault in pairs(vim.json.decode(vim.fn.readblob(obsidian_config_file)).vaults or {}) do
  table.insert(workspaces, { name = vim.fs.basename(vault.path), path = vault.path })
end

if #workspaces == 0 then
  return
end

require("obsidian").setup({
  workspaces = workspaces,

  legacy_commands = false,

  checkbox = {
    enabled = true,
    create_new = true,
    order = { " ", "/", "x" },
  },

  file = {
    ignore_filters = {
      ".trash/*",
    },
  },

  footer = {
    enabled = false,
  },

  frontmatter = {
    enabled = false,
  },

  ui = {
    enable = false,
  },
})

vim.keymap.set({ "n" }, "<leader>ow", "<cmd>Obsidian workspace<CR>")
vim.keymap.set({ "n" }, "<leader>of", "<cmd>Obsidian quick_switch<CR>")
vim.keymap.set({ "n" }, "<leader>og", "<cmd>Obsidian search<CR>")
vim.keymap.set({ "n" }, "<leader>od", "<cmd>Obsidian today<CR>")

vim.api.nvim_create_autocmd("User", {
  pattern = "ObsidianNoteEnter",
  callback = function(ev)
    vim.keymap.set({ "n", "v", "i" }, "<C-l>", "<cmd>Obsidian toggle_checkbox<cr>", {
      buffer = ev.buf,
      desc = "Toggle checkbox",
    })
  end,
})
