local hl = vim.api.nvim_set_hl
local augroup = vim.api.nvim_create_augroup   -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd   -- Create autocommand

local grp = augroup("UserGroup", { clear = true })

-- Remove whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = [[:%s/\s\+$//e"]],
  group = grp,
})
