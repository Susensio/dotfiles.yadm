safe_require = require("utils.require").safe

safe_require("config.options")
safe_require("config.keymaps")
safe_require("config.commands")
safe_require("config.autocmds")

if not vim.g.vscode then
  safe_require("config.lazy")
end
