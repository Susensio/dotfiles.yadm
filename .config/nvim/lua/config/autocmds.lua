local augroup = vim.api.nvim_create_augroup   -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd   -- Create autocommand
local lsp = require("utils.lsp")
local loclist = require("utils.loclist")
local user_grp = augroup("UserGroup", { clear = true })

autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function()
    vim.highlight.on_yank({
     higroup = "IncSearch",
      timeout = 100
    })
  end,
  group = user_grp,
})

autocmd("BufWritePre", {
  desc = "Remove trailing whitespace on save",
  callback = function()
    -- Save cursor position to later restore
    local curpos = vim.api.nvim_win_get_cursor(0)
    -- Search and replace trailing whitespace
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, curpos)
  end,
  group = user_grp,
})

autocmd("BufWinEnter", {
  desc = "Open help window in a vertical split if it fits better",
  pattern = {
    vim.fn.expand("$VIMRUNTIME") .. "/doc/*.txt",
    vim.fn.stdpath("state") .. "/lazy/readme/doc/*.{txt,md}",
    vim.fn.stdpath("data") .. "/lazy/*/doc/*.{txt,md}",
  },
  callback = function(ev)
    if not vim.bo[ev.buf].buftype == 'help' then
      return
    end
    -- First move to the very bottom
    vim.cmd.wincmd("J")
    local win_width = vim.api.nvim_win_get_width(0)
    local help_min_width = 78
    local more_than_double = win_width > 2 * help_min_width
    if more_than_double then
      -- Move the the very right
      vim.cmd.wincmd("L")
    end
  end,
  group = user_grp,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  desc = "Resize splits if window got resized",
  group = user_grp,
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  desc = "Auto create dir when saving a file, in case some intermediate directory does not exist",
  group = user_grp,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Diagnostics to location list
lsp.on_attach(
  function(client, buffer)
    -- BUG the first list is not being popullated
    autocmd({ "DiagnosticChanged", "BufWinEnter" }, {
      -- buffer = buffer,
      desc = "Put diagnostics on location list",
      callback = function(event)
        local lsp_clients = vim.lsp.get_active_clients({ bufnr = event.buf })
        if #lsp_clients == 0 then
          return
        end

        local is_normal_mode = vim.fn.mode() == "n"
        if not is_normal_mode then
          return
        end

        -- vim.notify("Setting loclist from diagnostic.", vim.log.levels.INFO)
        local opened = loclist.is_visible()
        vim.diagnostic.setloclist({ open = opened })
      end,
      group = augroup("DiagnosticLocList", { clear = true }),
    })
  end,
  { desc = "LSP diagnostic to location list" }
)

-- respects 'viewoptions'
autocmd("BufWinLeave", {
  desc = "Save folds and cursor",
  pattern = "?*",
  command = "silent! mkview!",
  group = user_grp,
})

autocmd("BufWinEnter", {
  desc = "Load folds and cursor",
  pattern = "?*",
  command = "silent! loadview",
  group = user_grp,
})

-- -- only highlight current line on focused window
-- autocmd({ "VimEnter", "WinEnter", "BufWinEnter", "FocusGained" }, {
--   desc = "Only highlight current line on focused window",
--   pattern = "*",
--   callback = function()
--     vim.opt_local.cursorline = true
--     vim.opt_local.relativenumber = true
--   end,
--   group = user_grp,
-- })
-- autocmd({ "WinLeave", "BufWinLeave", "FocusLost" }, {
--   desc = "Remove highlight current line on unfocused window",
--   pattern = "*",
--   callback = function()
--     vim.opt_local.cursorline = false
--     vim.opt_local.relativenumber = false
--   end,
--   group = user_grp,
-- })
