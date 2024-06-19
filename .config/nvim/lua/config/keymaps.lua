local map = require("utils.keymap").set
local map_ft = require("utils.keymap").set_per_filetype
local map_repeat = require("utils.keymap").set_repeatable
local log = require("utils.log")
local command = vim.api.nvim_create_user_command

local cmd = function(cmd)
  return "<cmd>" .. cmd .. "<CR>"
end

--[[ LEADER ]]
--
map({ "n", "v" }, "<Space>", nil)
vim.g.mapleader = " "


--[[ MOVEMENT ]]
--
-- Harcore
local hardcore = 1
if hardcore >= 1 then
  -- Disable arrow keys in NORMAL and VISUAL mode
  map({ "n", "x" }, "<Up>", nil)
  map({ "n", "x" }, "<Down>", nil)
  map({ "n", "x" }, "<Left>", nil)
  map({ "n", "x" }, "<Right>", nil)

  map("i", "<Up>", "<C-o>gk")
  map("i", "<Down>", "<C-o>gj")
end
if hardcore >= 2 then
  -- Disable arrow keys in INSERT mode
  map("i", "<Up>", nil)
  map("i", "<Down>", nil)
  map("i", "<Left>", nil)
  map("i", "<Right>", nil)
end
-- -- Remap control-arrow keys for movement
-- map("i", "<C-k>", "<C-o>gk")
-- map("i", "<C-j>", "<C-o>gj")
-- map("i", "<C-h>", "<Left>")
-- map("i", "<C-l>", "<Right>")

-- Is there a better use for control-movement in normal mode? LSP
-- map("n", "<C-k>", "gk")
-- map("n", "<C-j>", "gj")
-- map("n", "<C-h>", "j")
-- map("n", "<C-l>", "l")

-- Wrapped lines on text files
map_ft({ "text", "markdown" }, { "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map_ft({ "text", "markdown" }, { "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Half page up and down with recenter
-- map("n", "<C-u>", "<C-u>zz")
-- map("n", "<C-d>", "<C-d>zz")

-- Disable High, Medium and Low part of window
map("n", "H", nil)
map("n", "M", nil)
map("n", "L", nil)

--[[ SUPER KEYS ]]
--
-- map("i", "<Tab>", require("supertab").press, { desc = "SuperTab" })

-- Hide search results (activates back on search)
map("n", "<Esc>",
  function()
    if vim.fn.getcmdwintype() ~= "" then
      vim.cmd.wincmd("c")
      return
    end
    if vim.fn.win_gettype() == "popup" then
      vim.cmd.wincmd("c")
      return
    end
    vim.cmd.nohl()
    -- close floating windows from lsp and diagnostics
    vim.api.nvim_exec_autocmds("CursorMoved", {})
    -- if require("utils").close_floating_windows() then return end
    -- vim.cmd.lclose()
    -- close loclist if open, but only for current window

    -- clear command line
    vim.cmd("echo")
  end
)

-- mapa("i", "<Tab>")


--[[ SEARCH ]]
--
-- Search like * but without jumping to next match
-- map("n", "*",
--   function()
--     vim.fn.setreg("/", '\<' .. vim.fn.expand("<cword>") .. '\>' )
--     vim.opt_local.hlsearch = true
--   end,
--   { desc = "Highlight word under cursor" })

-- Search and replace word under cursor (\< \> are text boundaries)
map("n", "<Leader>s", [[:%s/\<<C-r><C-w>\>//g<Left><Left>]],
  { desc = "Replace word under cursor" })
-- Search and replace selected text (uses * register)
map("x", "<Leader>s", [["*ygv:<C-u>%s/\V<C-r>*//g<Left><Left>]],
  { desc = "Replace selected text" })



-- [[ INSERT and VISUAL ]] --
-- Completion menu
map("i", "<C-space>", "<C-x><C-o>", { desc = "Auto complete" })
map("i", "<CR>",
  function()
    if vim.fn.pumvisible() == 1 then
      return "<C-y>"
    else
      return "<CR>"
    end
  end,
  { desc = "Accept completion", expr = true })

-- Indent and preserve selection
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- Merge lines
map({ "n", "x" }, "M", "J", { desc = "Merge lines" })

-- Move text around
-- BUG: this has to be relative to the start of the selection
map("x", "J",
  function()
    return ":m '>+" .. (vim.v.count1) .. "<CR>gv=gv"
  end,
  { desc = "Move text down", expr = true, silent = true })
map("x", "K",
  function()
    return ":m '<-" .. (vim.v.count1 + 1) .. "<CR>gv=gv"
  end,
  { desc = "Move text up", expr = true, silent = true })

-- Add empty lines before and after cursor line
local add_line = function(before)
  local offset = 0
  if before then
    offset = -1
  end
  return function()
    local lines = {}
    for _ = 1, vim.v.count1 do
      table.insert(lines, "")
    end
    local current = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(
      0,
      current + offset,
      current + offset,
      true,
      lines
    )
  end
end
map_repeat('n', 'gO',
  add_line(true),
  { desc = "Add empty line before", expr = true }
)
map_repeat('n', 'go',
  add_line(false),
  { desc = "Add empty line after", expr = true }
)


map("x", "gc",
  function()
    if require("utils").is_visual_selection_empty() then
      return ":<C-U>lua require('vim._comment').textobject()<CR>"
    else
      return require('vim._comment').operator()
    end
  end,
  { desc = "Comment selection", expr = true }
)
-- https://www.reddit.com/r/neovim/comments/1deudx7/comment/l8er9vg/
map('x', 'gC', ':normal gcc<CR>', { desc = 'Invert comments' })

-- Select last pasted text
map("n", "gp", "`[v`]", { desc = "Reselect last pasted text" })

-- Emacs like deletes
-- map("i", "<C-K>", "<C-O>D", { desc = "Delete until end of line" })
map("c", "<C-K>", "<C-\\>e(strpart(getcmdline(), 0, getcmdpos() - 1))<CR>", { desc = "Delete until end of line" })

-- [[ BRACKETED ]] --
map("n", "[b", vim.cmd.bprevious, { desc = "Buffer previous" })
map("n", "]b", vim.cmd.bnext, { desc = "Buffer next" })

-- using <CMD> because error on last element is shorter. Why? Idk
map("n", "[q", "<CMD>cprevious<CR>", { desc = "Quickfix previous" })
map("n", "]q", "<CMD>cnext<CR>", { desc = "Quickfix next" })
map("n", "[l", "<CMD>lprevious<CR>", { desc = "Location previous" })
map("n", "]l", "<CMD>lnext<CR>", { desc = "Location next" })

map("n", "[t", vim.cmd.tabprevious, { desc = "Tab previous" })
map("n", "]t", vim.cmd.tabnext, { desc = "Tab next" })

map("n", "]g", "g;", { desc = "Change next" })
map("n", "[g", "g,", { desc = "Change previous" })


--[[ DIAGNOSTICS ]]
map("n", "<leader>ud",
  function()
    -- in case focus is in loclist
    local curr_win = vim.fn.getloclist(0, { all = 1 }).winid or vim.api.nvim_get_current_win()
    local curr_buf = vim.api.nvim_win_get_buf(curr_win)
    if not vim.diagnostic.is_enabled({ bufnr = curr_buf }) then
      vim.diagnostic.enable(true, { bufnr = curr_buf })
      vim.diagnostic.setloclist({ winnr = curr_win, open = false })
    else
      vim.diagnostic.enable(false, { bufnr = curr_buf })
      vim.fn.setloclist(curr_win, {})
      vim.cmd.lclose()
    end
    log.toggle("diagnostics", vim.diagnostic.is_enabled({ bufnr = curr_buf }))
  end,
  { desc = "Toggle diagnostics" })

map("n", "<leader>cd", function()
  local is_visible = require("utils.loclist").is_visible()
  if not is_visible then
    vim.diagnostic.setloclist({ open = true })
    vim.cmd.wincmd("p")
    -- if loclist not empty dict
    if #vim.fn.getloclist(0, { all = 1 }).items ~= 0 then
      require("utils.loclist").follow_cursor()
    end
    local _, winid = vim.diagnostic.open_float()
    if not winid then
      _, winid = vim.diagnostic.open_float({ scope = "line" })
    end
  else
    vim.cmd.lclose()
    vim.api.nvim_exec_autocmds("CursorMoved", {})
  end
end, { desc = "Open diagnostics list" })

map("n", "[d", function()
    vim.diagnostic.goto_prev({ wrap = false })
    require("utils.loclist").follow_cursor()
  end,
  { desc = "Diagnostic previous" })
map("n", "]d", function()
    vim.diagnostic.goto_next({ wrap = false })
    require("utils.loclist").follow_cursor()
  end,
  { desc = "Diagnostic next" })

--[[ LSP ]]
require("utils.lsp").on_attach(
  function(client, bufnr)
    local function lsp_map(mode, lhs, rhs, capability, opts)
      if capability == nil or not client.supports_method("textDocument/"..capability) then
        return
      end
      local options = vim.tbl_extend("keep", { buffer = bufnr }, opts)
      map(mode, lhs, rhs, options)
    end


    lsp_map("n", "K", vim.lsp.buf.hover, "hover", { desc = "Hover" })
    lsp_map("i", "<C-k>", vim.lsp.buf.signature_help, "signatureHelp", { desc = "Signature Help" })
    lsp_map("n", "gd", vim.lsp.buf.definition, "definition", { desc = "Goto Definition (LSP)" })
    lsp_map("n", "gD", vim.lsp.buf.declaration, "declaration", { desc = "Goto Declaration (LSP)" })
    lsp_map("n", "gr", vim.lsp.buf.references, "references", { desc = "Goto References (LSP)" })
    lsp_map("n", "<leader>cn", vim.lsp.buf.rename, "rename", { desc = "Rename (LSP)" })
    lsp_map("n", "<leader>cr", vim.lsp.buf.code_action, "codeAction", { desc = "Code Action" })
    lsp_map({ "n", "x" }, "<leader>cf", vim.lsp.buf.format, "documentFormatting", { desc = "Format Code" })
  end,
  { desc = "LSP keymaps" }
)


--[[ SPLITS AND TABS ]]
--
-- Split new
map("n", "<leader>-", vim.cmd.new, { desc = "Split horizontal new" })
map("n", "<leader>\\", vim.cmd.vnew, { desc = "Split vertical new" })
-- Split and copy
map("n", "<leader>_", vim.cmd.split, { desc = "Split horizontal copy" })
map("n", "<leader>|", vim.cmd.vsplit, { desc = "Split vertical copy" })

-- New tab
map("n", "<leader>t", vim.cmd.tabnew, { desc = "New tab" })

-- Zoom
local function zoom_toggle()
  if vim.t.maximized then
    vim.cmd.wincmd("=")
    vim.t["maximized"] = false
  else
    vim.t["maximized"] = true
    vim.cmd.wincmd("_")
    vim.cmd.wincmd("|")
  end
end
map("n", "<leader>z", zoom_toggle, { desc = "Toogle zoom" })
map("n", "<C-w>z", zoom_toggle, { desc = "Toogle zoom" })
-- map("n", "<leader>z",
--   function()
--     local has_splits = #vim.api.nvim_tabpage_list_wins(0) > 1
--
--     if has_splits then
--       -- save original tab
--       local origin = vim.api.nvim_get_current_tabpage()
--
--       -- zoom
--       vim.cmd("tab split")
--       local tabpagenr = vim.api.nvim_get_current_tabpage()
--       vim.t[tabpagenr].zoomed = origin
--     else
--       -- only one split
--       local tabpagenr = vim.api.nvim_get_current_tabpage()
--       if vim.t[tabpagenr].zoomed ~= nil then
--         -- and manually zoomed
--         local origin = vim.t[tabpagenr].zoomed
--         -- unzoom
--         vim.cmd("tab close")
--         vim.api.nvim_set_current_tabpage(origin)
--       end
--     end
--   end,
--   { desc = "Toogle zoom" }
-- )

-- Equalize
map("n", "<leader>=", "<C-w>=", { desc = "Equalize split sizes" })

-- Resize with hjkl
-- map("n", "<leader>k", ":resize +2<CR>")
-- map("n", "<leader>j", ":resize -2<CR>")
-- map("n", "<leader>h", ":vertical resize -2<CR>")
-- map("n", "<leader>l", ":vertical resize +2<CR>")


-- [[ SPELL ]]
map("n", "<leader>us",
  function()
    vim.opt_local.spell = not vim.opt_local.spell:get()
    log.toggle("spell", vim.opt_local.spell:get())
  end,
  { desc = "Toggle spell check" })
-- map("n", "<leader>uS", function() vim.opt.spell = not vim.opt.spell:get() end,
--   { desc = "Toggle spell check globally" })
map("n", "zz", "1z=", { desc = "Fix spelling mistake" })


--[[ BLACK HOLES ]]
-- When yanking and pasting, preserve yank in vim clipboard using blackhole
-- THIS can be done with P
-- map("x", "p", '"_dP', { desc = "Paste (overwrite)" })
-- D copies to register, X does not
map({ "n", "x" }, "x", '"_x')
map({ "n", "x" }, "X", '"_X')
-- dd, cc, S goes to blackhole if empty line
map("n", "dd", function()
  if vim.fn.getline(".") == "" then return '"_dd' end
  return "dd"
end, { expr = true })
map("n", "cc", function()
  if vim.fn.getline(".") == "" then return '"_cc' end
  return "cc"
end, { expr = true })
map("n", "S", function()
  if vim.fn.getline(".") == "" then return '"_S' end
  return "S"
end, { expr = true })
-- No yank alternatives (like helix)
-- map("n", "<M-c>", '"_c', { desc = "Change selection, without yanking" })
-- map("n", "<M-d>", '"_d', { desc = "Delete selection, without yanking" })


-- [[ ABBREVIATIONS ]] --
local abbrs = {
  W = "w",
  Wq = "wq",
  WQ = "wq",
  Q = "q",
  Qa = "qa",
}
for lhs, rhs in pairs(abbrs) do
  map("ca", lhs, rhs, { desc = "Abbreviation for " .. rhs })
end


-- [[ OTHERS ]] --
map("n", "<Leader>!", cmd "!%:p", { desc = "Execute current file" })

-- This is not working well because the file is no reloaded
map("ca", "w!!", "w !sudo tee % > /dev/null", { desc = "Write as sudo", silent = true })

-- [[ FIXES ]] --
-- wildoptions menu (:edit) correction for vertical horizontal navigation
map('c', '<Up>', 'wildmenumode() ? "<Left>" : "<Up>"', { expr = true, replace_keycodes = false })
map('c', '<Down>', 'wildmenumode() ? "<Right>" : "<Down>"', { expr = true, replace_keycodes = false })
map('c', '<Left>', 'wildmenumode() ? "<Up>" : "<Left>"', { expr = true, replace_keycodes = false })
map('c', '<Right>', 'wildmenumode() ? "<Down>" : "<Right>"', { expr = true, replace_keycodes = false })

-- map("c", "<C-h>", "<Left>", { remap = true })
-- map("c", "<C-j>", "<Down>", { remap = true })
-- map("c", "<C-k>", "<Up>", { remap = true })
-- map("c", "<C-l>", "<Right>", { remap = true })

--[[ DISABLED ]]
--
-- Disable command history `q:`, can still be accessed from command mode <Ctrl+R>
map("n", "q:", nil)
-- map("n", "q/", nil)
-- map("n", "q?", nil)

--[[ HELP ]]
--
-- Disable F1 help
map({ "n", "x", "i" }, "<F1>", nil)
-- Exit help with `q`
map_ft("help", "n", "q", vim.cmd.helpclose, { nowait = true, desc = "Quit help with `q`" })

-- Exit lazy with `<Esc>`
map_ft("lazy", "n", "<Esc>", function() vim.api.nvim_win_close(0, false) end,
  { desc = "Quit lazy with `<Esc>`", nowait = true })
map_ft("lazy", "n", "<Tab>", nil, { nowait = true })

-- Close some windows with `q`
map_ft("qf", "n", "q",
  function()
    -- vim.bo[buf].buflisted = false
    if vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1 then
      vim.cmd.lclose()
    else
      vim.cmd.cclose()
    end
    -- vim.api.nvim_win_close(0, true)
  end,
  { nowait = true, desc = "Close quickfix or loclist with `q`" }
)

-- https://github.com/benlubas/.dotfiles/blob/main/nvim%2Fafter%2Fftplugin%2Fqf.lua
local del_qf_item = function()
  local items = vim.fn.getqflist()
  local line = vim.fn.line('.')
  table.remove(items, line)
  vim.fn.setqflist(items, "r")
  if line > #items then
    line = #items
  end
  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

map_ft("qf", "n", "dd", del_qf_item, { silent = true, desc = "Remove entry from QF" })
map_ft("qf", "v", "D", del_qf_item, { silent = true, desc = "Remove entry from QF" })
