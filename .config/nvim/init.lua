safe_require = require("utils.require").safe

safe_require("config.options")
safe_require("config.keymaps")
safe_require("config.commands")
safe_require("config.autocmds")

safe_require("config.lazy")
