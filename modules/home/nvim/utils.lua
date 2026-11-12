local M = {}

local function get_floating_window_size()
  local max_height = vim.o.lines - 1
  local max_width = vim.o.columns

  local win_height = math.ceil(max_height / 1.1)
  local win_width = math.ceil(max_width / 1.2)

  return {
    row = math.floor((max_height - win_height) / 2),
    col = math.floor((max_width - win_width) / 2),
    width = win_width,
    height = win_height,
  }
end

function M.open_floating_window(buf, title)
  local win = vim.api.nvim_open_win(
    buf,
    true,
    vim.tbl_extend("force", { relative = "editor", title = title }, get_floating_window_size())
  )

  local autocmd_id = vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      vim.api.nvim_win_set_config(win, vim.tbl_extend("force", vim.api.nvim_win_get_config(win), get_floating_window_size()))
    end,
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    once = true,
    callback = function()
      vim.api.nvim_del_autocmd(autocmd_id)
    end,
  })
end

-- Para pasarle contexto al agente: ruta#Llínea o la selección como bloque de código (de craftzdog/dotfiles)
local function yank(text, msg)
  vim.fn.setreg("+", text)
  vim.notify(msg or ("Copiado: " .. text))
end

function M.yank_path_with_line(modifier)
  yank(vim.fn.expand("%" .. modifier) .. "#L" .. vim.fn.line("."))
end

function M.copy_as_codeblock()
  local first, last = vim.fn.line("'<"), vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local header = "```" .. vim.bo.filetype .. ' filename="' .. vim.fn.expand("%:.") .. '" line=' .. first
  yank(table.concat({ header, table.concat(lines, "\n"), "```" }, "\n"), "Copiadas " .. #lines .. " líneas como bloque")
end

return M
