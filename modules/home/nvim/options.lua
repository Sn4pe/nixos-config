-- UI
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"

vim.o.winborder = "rounded"

vim.o.showmode = false
vim.o.cmdheight = 0

vim.o.cursorline = true

vim.o.termguicolors = true

vim.o.wrap = false

vim.o.swapfile = false

-- Split windows
vim.o.splitbelow = true
vim.o.splitright = true

-- Indentation
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Diagnostic icons
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
})
