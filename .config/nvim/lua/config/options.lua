local set = vim.opt
local highlight = vim.api.nvim_set_hl
local env = vim.env     -- environment variables

-- Filename on the title
set.title = true

-- Visuals
set.number = true
set.relativenumber = true
set.background = "dark"
if env.USER == "root" then
    highlight(0, "LineNr", {ctermfg = "red"})
else
    highlight(0, "LineNr", {ctermfg = "grey"})
end
set.cursorline = true
set.encoding = "utf-8" 

-- Wrap long lines
set.wrap = true
set.linebreak = true
set.breakindent = true

-- Mouse selection and clipboard
set.mouse = "a"
set.clipboard = "unnamedplus"

-- Tabs
set.expandtab = true
set.tabstop = 2
set.shiftwidth = 2
set.softtabstop = 2

-- Search
set.ignorecase = true
set.smartcase = true
set.hlsearch = false

-- Save file
set.undofile = true
set.swapfile = true
set.fileencoding = "utf-8" 

-- Splits
set.splitbelow = true
set.splitright = true

-- As one word
set.iskeyword:append("-")

-- Show non printable characters
set.list = true
set.listchars = "tab:»»,trail:·,nbsp:+,eol:↲"
