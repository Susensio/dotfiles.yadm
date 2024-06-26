return {
  { -- mini.splitjoin
    "echasnovski/mini.splitjoin",
    keys = {
      { mode = "n", "gS", desc = "Toggle arguments" },
    },
    config = true,
  },

  { -- mini.operators
    "echasnovski/mini.operators",
    init = function(plugin)
      vim.keymap.set("n", "S", "s$", { noremap = true })
    end,
    keys = {
      { mode = { "n", "x" }, "g=", desc = "Evaluate" },
      { mode = { "n", "x" }, "gx", desc = "Exchange" },
      { mode = { "n", "x" }, "gm", desc = "Multiply" },
      { mode = { "n", "x" }, "s", desc = "Replace" },

      -- { mode = "n", "gs", desc = "Sort" },
    },
    opts = {
      evaluate = {
        prefix = "g=",
      },

      -- Exchange text regions
      exchange = {
        prefix = "gx",
      },

      -- Multiply (duplicate) text
      multiply = {
        prefix = "gm",
      },

      -- Replace text with register (Substitute)
      replace = {
        prefix = "s",
      },

      -- Sort text
      sort = {
        -- prefix = "gs",
        prefix = "",
      }
    },
  },
}
