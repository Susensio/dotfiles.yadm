vim.g.mapleader = " "
vim.g.localmapleader = " "

require("config.lazy")

safe_require = require("utils.require").safe

safe_require("config.options")
safe_require("config.keymaps")
safe_require("config.commands")
safe_require("config.autocmds")
