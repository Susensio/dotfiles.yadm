-- Aliases for setting options, highlight and environment variables.
local set = vim.opt
local highlight = vim.api.nvim_set_hl
local env = vim.env

local augroup = vim.api.nvim_create_augroup   -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd   -- Create autocommand

-- GENERAL SETTINGS: Editor behavior, window management, and file encoding.
set.title = true                              -- Enable filename in window title
set.shortmess:append("I")                     -- Disable the startup message
set.mouse = "a"                               -- Enable mouse support
set.clipboard = "unnamedplus"                 -- Use the clipboard for all operations
set.undofile = true                           -- Save undo history
set.swapfile = true                           -- Enable swapfile
set.fileencoding = "utf-8"                    -- Set default file encoding
set.splitbelow = true                         -- Horizontal splits will go below current window
set.splitright = true                         -- Vertical splits will go to the right of current window
set.path = ".,**"                             -- Set the search path to current dir and subdirs
vim.g.do_filetype_lua = 1                     -- Use filetype.lua for filetype detection
set.spellsuggest:append("9")                  -- The maximum number of suggestions listed
set.spelllang = "en,es_es"                    -- Set spell check language
set.shell = "/usr/bin/bash"                   -- Avoid pluggin problems
set.isfname:append("{,}")                  -- Include curly braces in file name (${VAR})

-- VISUAL SETTINGS: Theme, cursor appearance, line numbers, folding and text display.
set.termguicolors = true                     -- Enable true color support
set.background = "dark"                      -- Use a dark background
set.number = true                            -- Show line numbers
set.relativenumber = true                    -- Show relative line numbers
set.signcolumn = "yes:1"                     -- Do not append an extra column for diagnostics
set.cursorline = true                        -- Highlight the current line
set.guicursor = ""
set.guicursor:append("n-v-c-sm:block")       -- Block non insert mode
set.guicursor:append("i-ci-ve:ver25")        -- Insert mode vertical
set.guicursor:append("i-ci-ve-c:blinkon700") -- Blink cursor in insert mode
set.guicursor:append("i-ci-ve-c:iCursor")    -- Different color in insert mode
set.guicursor:append("r-cr-o:hor20")
set.foldmethod = "indent"                    -- Set fold method to indent
set.foldtext = ""                            -- Disable fold text
set.foldlevel = 99                           -- Start with all folds open
set.foldlevelstart = 99                      -- Start with all folds open
set.list = true                              -- Show non printable characters
set.listchars = {                            -- Define characters for non printable chars
   tab = "» ",
   trail = "·",
   nbsp = "+",
   eol = "↲",
}
set.fillchars = {
   foldopen = "",
   foldsep = " ",
   foldclose = "",
}

-- Special highlighting for root user
if env.USER == "root" then
   highlight(0, "LineNr", {ctermfg = "red"})
else
   highlight(0, "LineNr", {ctermfg = "grey"})
end

-- LSP
local lsp = require("utils.lsp")
lsp.on_attach(
   function(client, buffer)
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
         vim.lsp.handlers.hover,
         { border = "single" }
      )
      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
         vim.lsp.handlers.signature_help,
         { border = "single" }
      )
   end,
   { once = true, desc = "LSP hover and signature help borders" }
)

-- Diagnostics
set.updatetime = 1000                         -- User for CursorHold autocmd
lsp.on_attach(
   function(client, buffer)
      vim.diagnostic.config({
         update_on_insert = false,
         virtual_text = {
            severity = { min = vim.diagnostic.severity.WARN },
            format = function(diagnostic)
               local MIN_WIDTH = 15
               local MAX_WIDTH = 80
               local first_line = diagnostic.message:gmatch("[^\n]*")()
               -- BUG: this fails if the first sentence has a dot inside quotes
               local patterns = {
                  "(.-[^%.]%. )",   -- first sentence
                  "(.-): ",         -- first lhs
               }
               local result = first_line
               while #first_line > MAX_WIDTH do
                  -- pop the first pattern
                  local pattern = table.remove(patterns, 1)
                  if not pattern then break end
                  local reduced = result:match(pattern) or result
                  if #reduced > MIN_WIDTH then
                     result = reduced
                  end
               end
               return result
            end
         },
         severity_sort = true,
         float = {
            border = "single",
            focusable = false,
            scope = "cursor",
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            header = false,
            title_pos = "left",
            prefix = " ",
            suffix = " ",
         },
      })
      -- Highlight line number instead of having icons in sign column
      for _, diag in ipairs({ "Error", "Warn", "Info", "Hint" }) do
         local name = "DiagnosticSign" .. diag
         vim.fn.sign_define(name, {text = "", texthl = name, linehl = "", numhl = name,})
      end
   end,
   { once = true, desc = "LSP diagnostic settings" }
)

-- Completion
set.completeopt = {
   "menuone",  -- Show the popup menu even if there is only one match
   "longest",
}
set.shortmess:append("c")                     -- Do not show completion messages

-- BEHAVIOR SETTINGS: Tabs, scrolling, search, and special characters handling.
set.wrap = true                               -- Wrap long lines
set.linebreak = true                          -- Wrap lines at word (not in the middle of a word)
set.breakindent = true                        -- Indented wrapped lines
set.scrolloff = 10                            -- Keep 10 lines above/below the cursor
set.expandtab = true                          -- Convert tabs to spaces
set.tabstop = 2                               -- Number of spaces a tab counts for
set.shiftwidth = 2                            -- Number of spaces to use for (auto)indent step
set.softtabstop = 2                           -- Number of spaces a tab counts for while performing editing operations
set.ignorecase = true                         -- Ignore case in search patterns
set.smartcase = true                          -- Override ignorecase if search pattern has uppercase letters
set.hlsearch = true                           -- Do not highlight search results
set.iskeyword:append("-")                     -- Treat dash as a word character
set.jumpoptions = "view"                      -- Avoid scrolling when switching buffer
set.wrapscan = true                           -- Searches wrap around the end of the file

-- Configure new line comment. This is set on filetype, so it must be changed after
autocmd("Filetype", {
   pattern = "*",
   desc = "Disable New Line Comment",
   callback = function()
      vim.opt_local.formatoptions:remove("o") -- Do not continue comments on new line <o>
      vim.opt_local.formatoptions:append("r") -- Insert comment after hitting <Enter>
   end,
   group = augroup("FormatOptions", { clear = true }),
})

-- if ripgrep installed, use that as a grepper
if vim.fn.executable("rg") then
   set.grepprg = "rg --vimgrep --no-heading --smart-case"
   set.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

-- Clipboard and Mouse Integration
vim.keymap.set(
   "v", "<LeftRelease>",
   function()
      set.eventignore = "TextYankPost"
      vim.cmd.normal('"*ygv')
      set.eventignore = ""
      -- WHY do i have to select two times??
      vim.cmd.normal('gv')
   end,
   { silent = true }
)

-- Configure clipboard with a user script
vim.g.clipboard = {
   name = "clipboard",
   copy = {
      ["+"] = {"clipboard", "copy", "--selection", "clipboard"},
      ["*"] = {"clipboard", "copy", "--selection", "primary"}
   },
   paste = {
      ["+"] = {"clipboard", "paste", "--selection", "clipboard"},
      ["*"] = {"clipboard", "paste", "--selection", "primary"}
   },
   cache_enabled = 0
}
