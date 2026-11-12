-- lazygit flotante. Con `e` el archivo se abre en la ventana desde la que se lanzó, no en un nvim
-- anidado: el os.edit de dev.nix habla con este nvim por $NVIM y llama a focus_origin
local utils = require("config.utils")

local M = {}

local origin_win

function M.open()
  origin_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].lazygit = true
  utils.open_floating_window(buf, "lazygit")
  local win = vim.api.nvim_get_current_win()
  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })
  vim.cmd.startinsert()
end

function M.focus_origin()
  if origin_win and vim.api.nvim_win_is_valid(origin_win) then
    vim.api.nvim_set_current_win(origin_win)
  end
end

return M
