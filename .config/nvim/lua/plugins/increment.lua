return {
  { -- dial
    "monaqa/dial.nvim",
    version = false,
    enabled = true,
    init = function()
      vim.keymap.set("n", "<C-a>", function()
        require("dial.map").manipulate("increment", "normal")
      end)
      vim.keymap.set("n", "<C-x>", function()
        require("dial.map").manipulate("decrement", "normal")
      end)
      vim.keymap.set("n", "g<C-a>", function()
        require("dial.map").manipulate("increment", "gnormal")
      end)
      vim.keymap.set("n", "g<C-x>", function()
        require("dial.map").manipulate("decrement", "gnormal")
      end)
      vim.keymap.set("v", "<C-a>", function()
        require("dial.map").manipulate("increment", "visual")
      end)
      vim.keymap.set("v", "<C-x>", function()
        require("dial.map").manipulate("decrement", "visual")
      end)
      vim.keymap.set("v", "g<C-a>", function()
        require("dial.map").manipulate("increment", "gvisual")
      end)
      vim.keymap.set("v", "g<C-x>", function()
        require("dial.map").manipulate("decrement", "gvisual")
      end)
    end,
    config = function(plugin, opts)
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          -- augend.constant.alias.bool,
          augend.constant.new({
            elements = { "false", "true" },
            word = true,
            cyclic = false,
          }),
          augend.constant.new({
            elements = { "False", "True" },
            word = true,
            cyclic = false,
          }),
          augend.constant.new {
            elements = { "and", "or" },
            word = true,
            cyclic = true,
          },
          augend.constant.new {
            elements = { "&&", "||" },
            word = false,
            cyclic = true,
          },
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%m/%d"],
          augend.date.alias["%H:%M"],
          augend.constant.new({
            elements = { "TRACE", "DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL" },
            word = true,
            cyclic = false,
          }),
          augend.constant.new({
            elements = { "trace", "debug", "info", "success", "warning", "error", "critical" },
            word = true,
            cyclic = false,
          })
        },
      })
    end,
  },
}
