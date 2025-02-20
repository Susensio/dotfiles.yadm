safe_require = require("utils.require").safe

vim.g.mapleader = " "
vim.g.localmapleader = " "

safe_require("config.options")
safe_require("config.keymaps")

safe_require("config.lazy")

safe_require("config.commands")
safe_require("config.autocmds")
