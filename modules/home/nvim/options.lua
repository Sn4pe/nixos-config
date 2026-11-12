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

-- De craftzdog/dotfiles
vim.o.scrolloff = 10
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.opt.fillchars:append("diff:╱")

-- Mensajes en ventana flotante (con cmdheight = 0 si no se pierden). Errores y salidas largas, en el pager
require("vim._core.ui2").enable({
  msg = {
    target = "msg",
    targets = {
      emsg = "pager",
      echoerr = "pager",
      lua_error = "pager",
      list_cmd = "pager",
      shell_out = "pager",
      shell_err = "pager",
      verbose = "pager",
    },
    msg = { height = 0.3, timeout = 5000 },
    pager = { height = 0.5 },
  },
})
