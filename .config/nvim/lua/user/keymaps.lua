local keymap = vim.keymap.set
local opts = { silent = true }

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Escape insert mode with `jk` and `kj`
-- handled by "max397574/better-escape.nvim"

-- Open side explorer
keymap("n", "<leader>e", ":Lex 30<cr>", opts)
-- keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Indent with <Tab>
keymap("v", "<S-Tab>", "<gv", opts)
keymap("v", "<Tab>", ">gv", opts)

-- CENTERING
-- Next search
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)

-- Half page up and down
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)


-- -- Better window navigation
vim.keymap.set({'n', 't', 'i'}, '<M-h>', '<CMD>NavigatorLeft<CR>')
vim.keymap.set({'n', 't', 'i'}, '<M-l>', '<CMD>NavigatorRight<CR>')
vim.keymap.set({'n', 't', 'i'}, '<M-k>', '<CMD>NavigatorUp<CR>')
vim.keymap.set({'n', 't', 'i'}, '<M-j>', '<CMD>NavigatorDown<CR>')
-- vim.keymap.set({'n', 't'}, '<M-p>', '<CMD>NavigatorPrevious<CR>')
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
--
-- -- Resize with arrows
-- keymap("n", "<M-Up>", ":resize +2<CR>", opts)
-- keymap("n", "<M-Down>", ":resize -2<CR>", opts)
-- keymap("n", "<M-Left>", ":vertical resize -2<CR>", opts)
-- keymap("n", "<M-Right>", ":vertical resize +2<CR>", opts)

-- Move text up and down
-- And select after?????
-- keymap("v", "<A-j>", ":m .+1<CR>==", opts)
-- keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- When yanking and pasting, preserve yank in vim clipboard
keymap("v", "p", '"_dP', opts)
