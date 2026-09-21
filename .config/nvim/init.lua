vim.loader.enable()

vim.g.mapleader = " "

-- Editor
local opt = vim.opt

opt.clipboard = "unnamedplus"
opt.relativenumber = true
opt.scrolloff = 5
opt.wrap = true
opt.list = true
opt.listchars = "tab:» ,trail:·,eol:↲,extends:…,precedes:…,nbsp:␣"
opt.expandtab = true
opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4

-- Motions and editing
local map = vim.keymap.set

-- `matchit` takes `%`; this mapping intentionally selects the whole buffer instead.
vim.g.loaded_matchit = true
map("n", "%", "ggVG", { desc = "Select entire file" })
map("n", "ge", "G", { desc = "Goto last line" })
map("n", "U", "<C-r>", { desc = "Redo" })

map({ "n", "x", "o" }, "H", "^", { desc = "Jump to start of line" })
map({ "n", "x", "o" }, "L", "$", { desc = "Jump to end of line" })

map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

map("n", "x", "V", { desc = "Select current line" })
map("x", "x", "j", { desc = "Extend selection one line down" })

map("n", "<Esc>", function()
   if vim.v.hlsearch == 1 then
      vim.cmd("nohlsearch")
   end
end, { desc = "Clear search highlight" })

map("n", "<C-c>", "gcc", { desc = "Toggle comment on current line" })
map("x", "<C-c>", "gc", { desc = "Toggle comment on selection" })

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gy", vim.lsp.buf.type_definition, { desc = "Go to type definition" })

map("n", "<leader>R", function()
   vim.cmd("source " .. vim.fn.expand("$MYVIMRC"))
   vim.notify("Config reloaded!", vim.log.levels.INFO, { timeout = 2000 })
end, { desc = "Reload config" })

-- Packages
-- Managed by vim.pack and pinned in nvim-pack-lock.json.
local gh = function(repo)
   return "https://github.com/" .. repo
end

vim.api.nvim_create_user_command("PackUpdate", function()
   vim.pack.update()
end, { desc = "Update installed packages" })
vim.api.nvim_create_user_command("PackDelete", function(args)
   vim.pack.del(args.fargs)
end, { desc = "Delete installed packages", nargs = "+" })

vim.pack.add({
   gh("nvim-mini/mini.nvim"),
   "ellisonleao/gruvbox.nvim",
   gh("folke/lazydev.nvim"),
   gh("nvim-treesitter/nvim-treesitter"),
   gh("nvim-treesitter/nvim-treesitter-textobjects"),
   gh("neovim/nvim-lspconfig"),
})

require("mini.basics").setup({ mappings = { option_toggle_prefix = "" } })

-- Appearance
require("gruvbox").setup({
   overrides = {
      Normal = { bg = "none" }, -- Allow tmux pane dimming.
   },
})
vim.cmd.colorscheme("gruvbox")

local miniclue = require("mini.clue")
miniclue.setup({
   triggers = {
      { mode = { "n", "x" }, keys = "<Leader>" },
      { mode = "n", keys = "[" },
      { mode = "n", keys = "]" },
      { mode = "i", keys = "<C-x>" },
      { mode = { "n", "x" }, keys = "g" },
      { mode = { "n", "x" }, keys = "'" },
      { mode = { "n", "x" }, keys = "`" },
      { mode = { "n", "x" }, keys = '"' },
      { mode = { "i", "c" }, keys = "<C-r>" },
      { mode = "n", keys = "<C-w>" },
      { mode = { "n", "x" }, keys = "z" },
   },
   clues = {
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
   },
})

require("mini.icons").setup()

-- Find
local pick = require("mini.pick")
pick.setup()

map("n", "<leader>f", function()
   pick.builtin.files(
      {},
      { source = { cwd = vim.fs.root(0, ".git") or vim.fn.getcwd() } }
   )
end, { desc = "Find file in project root" })
map("n", "<leader>F", pick.builtin.files, { desc = "Find file in cwd" })
map("n", "<leader>g", function()
   pick.builtin.grep_live(
      {},
      { source = { cwd = vim.fs.root(0, ".git") or vim.fn.getcwd() } }
   )
end, { desc = "Search project" })
map(
   "n",
   "<leader>G",
   require("mini.extra").pickers.git_hunks,
   { desc = "Git hunks" }
)
map("n", "<leader>b", pick.builtin.buffers, { desc = "Buffers" })

local misc = require("mini.misc")
misc.setup_restore_cursor()

-- Text objects
-- Built-in objects cover words, paragraphs, pairs, and quotes.
-- Tree-sitter adds functions, types, arguments, and comments.
local ai = require("mini.ai")
ai.setup({
   mappings = {
      around_next = "",
      inside_next = "",
      around_last = "",
      inside_last = "",
      goto_left = "",
      goto_right = "",
   },
   custom_textobjects = {
      f = ai.gen_spec.treesitter({
         a = "@function.outer",
         i = "@function.inner",
      }),
      t = ai.gen_spec.treesitter({
         a = { "@class.outer", "@block.outer" },
         i = { "@class.inner", "@block.inner" },
      }),
      a = ai.gen_spec.treesitter({
         a = "@parameter.outer",
         i = "@parameter.inner",
      }),
      c = ai.gen_spec.treesitter({ a = "@comment.outer", i = "@comment.inner" }),
   },
})

-- UI
-- Keep the mode width stable and the filename anchored on the left.
local statusline = require("mini.statusline")
statusline.setup({
   content = {
      active = function()
         local mode, mode_hl = statusline.section_mode({ trunc_width = 0 })
         mode = mode:sub(1, 3):upper()
         local filename = statusline.section_filename({ trunc_width = math.huge })
         local diagnostics =
            statusline.section_diagnostics({ trunc_width = 75 })
         local position =
            string.format("%d:%d", vim.fn.line("."), vim.fn.col("."))

         return statusline.combine_groups({
            { hl = mode_hl, strings = { mode } },
            "%<",
            { hl = "MiniStatuslineFilename", strings = { filename } },
            "%=",
            { hl = "MiniStatuslineDevinfo", strings = { diagnostics } },
            { hl = mode_hl, strings = { position } },
         })
      end,
   },
})

require("mini.surround").setup({
   mappings = {
      add = "s",
      delete = "ds",
      replace = "cs",
      find = "",
      find_left = "",
      highlight = "",
      suffix_last = "",
      suffix_next = "",
   },
   search_method = "cover_or_next",
})

require("mini.cmdline").setup({
   autocomplete = {
      -- Search prompts should stay plain.
      predicate = function()
         return vim.fn.getcmdtype() == ":"
      end,
   },
})
require("mini.notify").setup({
   lsp_progress = { enable = false },
   window = { winblend = 0 },
})
require("mini.completion").setup({})

-- Show only the diagnostic for the current line below the buffer text.
vim.diagnostic.config({
   virtual_text = false,
   virtual_lines = { current_line = true },
})

-- Language tooling
-- LazyDev gives LuaLS Neovim runtime metadata.
require("lazydev").setup({})

-- Ensure parsers are installed; highlighting starts when a matching buffer opens.
require("nvim-treesitter").install({
   "bash",
   "fish",
   "javascript",
   "json",
   "lua",
   "toml",
   "typescript",
   "vim",
   "yaml",
})
local config_group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
   group = config_group,
   callback = function()
      -- No parser is normal for unsupported file types.
      pcall(vim.treesitter.start)
   end,
   desc = "Start tree-sitter highlighting",
})

vim.api.nvim_create_autocmd("PackChanged", {
   group = config_group,
   callback = function(ev)
      if
         ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update"
      then
         vim.cmd("TSUpdate")
      end
   end,
   desc = "Update tree-sitter parsers",
})

vim.lsp.enable({
   "bashls",
   "biome",
   "fish_lsp",
   "lua_ls",
   "taplo",
   "ty",
   "yamlls",
})

vim.api.nvim_create_user_command("Fmt", function()
   vim.lsp.buf.format({ async = false })
end, { desc = "Format buffer with LSP" })
