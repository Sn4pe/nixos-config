local utils = require("config.utils")

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Teclado es: ñ es la tecla del ; inglés, - la del / y ç/Ç sustituyen a ]/[ (AltGr)
vim.keymap.set({ "n", "x" }, "ñ", ":")
vim.keymap.set({ "n", "x", "o" }, "-", "/")
vim.keymap.set({ "n", "x", "o" }, "ç", "]", { remap = true })
vim.keymap.set({ "n", "x", "o" }, "Ç", "[", { remap = true })

local function getDiagnosticJumpFunction(count)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = {
        min = vim.diagnostic.severity.WARN,
      },
      wrap = true,
    })
  end
end

-- Keep screen centered on jumps
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Split navigation
vim.keymap.set({ "n", "v" }, "<C-h>", "<C-w>h")
vim.keymap.set({ "n", "v" }, "<C-j>", "<C-w>j")
vim.keymap.set({ "n", "v" }, "<C-k>", "<C-w>k")
vim.keymap.set({ "n", "v" }, "<C-l>", "<C-w>l")

-- LSP
vim.keymap.set({ "n" }, "gd", vim.lsp.buf.definition, { desc = "Go to definition under cursor" })
vim.keymap.set({ "n" }, "<leader>dp", getDiagnosticJumpFunction(-1), { desc = "Go to previous diagnostic" })
vim.keymap.set({ "n" }, "<leader>dn", getDiagnosticJumpFunction(1), { desc = "Go to next diagnostic" })

-- Tools
vim.keymap.set({ "n" }, "<leader>lg", function()
  local buf = vim.api.nvim_create_buf(false, true)
  utils.open_floating_window(buf, "lazygit")
  vim.api.nvim_command(":terminal lazygit")
end, { desc = "Open lazygit in a floating window" })

-- Clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system's clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system's clipboard" })
