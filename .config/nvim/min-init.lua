-- minimal config for testing plugins

local lazypath = "/tmp/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system { "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true

require("lazy").setup ({
    {
        "sainnhe/everforest",
        config = function()
            vim.cmd.colorscheme("everforest")
        end,
    },
}, { root = "/tmp/lazy" })

