local keymap = vim.keymap.set
local opts = { silent = true }
local noremap = { noremap = true }

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Escape insert mode with `jk` and `kj`
-- handled by "max397574/better-escape.nvim"

-- Open side explorer
keymap("n", "<leader>e", ":Lex 30<cr>", { desc = "Show side explorer" }, opts)
-- keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Indent with <Tab> and preserve selection
-- keymap("v", "<S-Tab>", "<gv", opts)
-- keymap("v", "<Tab>", ">gv", opts)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- CENTERING
-- Next search
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)

-- Half page up and down
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)

-- Move text around
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text up" })  -- overrides joining lines in visual mode
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text down" })

-- Search and replace word under cursor
keymap("n", "<Leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left>]],
  { desc = "Search and replace word under cursor"})

-- Select all
keymap({"n", "v"}, "<C-a>", "ggVG", { noremap = true, desc = "Select all" })

-- Add and substract with numpad
keymap({"n", "v"}, "+", "<C-a>", noremap)
keymap("v", "g+", "g<C-a>", noremap)
keymap({"n", "v"}, "-", "<C-x>", noremap)
keymap("v", "g-", "g<C-x>", noremap)

-- Better window navigation
-- already defined in plugins/tmux.lua
-- keymap({"n", "t", "i"}, "<M-h>", "<CMD>NavigatorLeft<CR>")
-- keymap({"n", "t", "i"}, "<M-l>", "<CMD>NavigatorRight<CR>")
-- keymap({"n", "t", "i"}, "<M-k>", "<CMD>NavigatorUp<CR>")
-- keymap({"n", "t", "i"}, "<M-j>", "<CMD>NavigatorDown<CR>")
-- keymap({"n", "t"}, "<M-p>", "<CMD>NavigatorPrevious<CR>")
--
-- keymap("n", "<M-h>", "<C-w>h", opts)
-- keymap("n", "<M-j>", "<C-w>j", opts)
-- keymap("n", "<M-k>", "<C-w>k", opts)
-- keymap("n", "<M-l>", "<C-w>l", opts)
--
-- -- keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", opts)
-- -- keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", opts)
-- -- keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", opts)
-- -- keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", opts)

-- Split like tmux
keymap("n", "<leader>-", ":new<CR>", { noremap = true, desc = "Split horizontal new" })
keymap("n", "<leader>\\", ":vnew<CR>", { noremap = true, desc = "Split vertical new" })
-- Split and copy
keymap("n", "<leader>_", ":split<CR>", { noremap = true, desc = "Split horizontal copy" })
keymap("n", "<leader>|", ":vsplit<CR>", { noremap = true, desc = "Split vertical copy" })


-- Resize with hjkl
keymap("n", "<leader>k", ":resize +2<CR>", opts)
keymap("n", "<leader>j", ":resize -2<CR>", opts)
keymap("n", "<leader>h", ":vertical resize -2<CR>", opts)
keymap("n", "<leader>l", ":vertical resize +2<CR>", opts)

-- Move text up and down
-- And select after?????
-- keymap("v", "<A-j>", ":m .+1<CR>==", opts)
-- keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- When yanking and pasting, preserve yank in vim clipboard
keymap("v", "p", '"_dP', opts)
-- D copies to register, X does not
keymap({"n","v"}, "x", '"_x', opts)

-- Disable command history `q:`, can still be accessed from command mode <Ctrl+F>
keymap("n", "q:", "<nop>")

-- wildoptions menu (:edit) correction for vertical horizontal navigation
keymap('c', '<Up>', 'wildmenumode() ? "<Left>" : "<Up>"', {expr = true, noremap=true, replace_keycodes=false})
keymap('c', '<Down>', 'wildmenumode() ? "<Right>" : "<Down>"', {expr = true, noremap=true, replace_keycodes=false})
keymap('c', '<Left>', 'wildmenumode() ? "<Up>" : "<Left>"', {expr = true, noremap=true, replace_keycodes=false})
keymap('c', '<Right>', 'wildmenumode() ? "<Down>" : "<Right>"', {expr = true, noremap=true, replace_keycodes=false})
