local colorscheme = "monokai"

local highlight = vim.api.nvim_set_hl

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
else
  -- Maintain terminal background color
  highlight(0, "Normal", { ctermfg="NONE" })

  -- Current line less intrusive
  highlight(0, "CursorLine", { bg = "#272727" })

  -- Line number
  highlight(0, "LineNr", { fg="grey" })
end
