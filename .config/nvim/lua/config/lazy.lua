-- Automatically install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
  "git",
  "clone",
  "--filter=blob:none",
   "https://github.com/folke/lazy.nvim.git",
   "--branch=stable", -- latest stable release
   lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


return require("lazy").setup("plugins", {
  defaults = {
    lazy = true,
    version = false,
  },
  checker = { enabled = true },
  change_detection = {
    enable = true,
    notify = false,
  },
  install = {
    missing = true,
    colorscheme = { "monokai" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
       },
     },
   },
})
