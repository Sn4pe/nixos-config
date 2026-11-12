local function setIndentationWidth(pattern, indentation)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = pattern,
    callback = function()
      vim.opt_local.shiftwidth = indentation
      vim.opt_local.tabstop = indentation
    end,
  })
end

-- nvim-treesitter (rama main) ya no arranca el resaltado: se hace aquí para las gramáticas instaladas
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "wincmd =",
  desc = "Automatically resize windows when the host window size changes.",
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "BufWinEnter", "WinEnter", "TermOpen" }, {
  pattern = "term://*",
  callback = function()
    vim.api.nvim_command("startinsert")
  end,
})

vim.api.nvim_create_autocmd({ "TermClose" }, {
  pattern = "term://*",
  callback = function(ev)
    -- Fuera de la vista el ENTER caería en otro buffer. lazygit se cierra solo (config.lazygit)
    if ev.buf == vim.api.nvim_get_current_buf() and not vim.b[ev.buf].lazygit then
      vim.api.nvim_input("<CR>")
    end
  end,
  desc = "Press ENTER when closing a terminal to skip the 'Process exited' text",
})

-- Recarga lo que cambie el agente por fuera, si el buffer no tiene cambios sin guardar
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd.checktime()
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Indentation
setIndentationWidth("*.lua", 2)
setIndentationWidth("*.nix", 2)
