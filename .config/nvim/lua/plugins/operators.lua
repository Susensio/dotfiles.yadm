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
         vim.keymap.set("n", "S",
            function()
               require("mini.operators").replace()
               return "g@$"
            end,
            {
               expr = true,
               replace_keycodes = false,
               desc = "Replace until EOL"
            })
      end,
      keys = {
         { mode = { "n", "x" }, "g=", desc = "Evaluate" },
         -- { mode = { "n", "x" }, "gx", desc = "Exchange" },
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
            prefix = "",
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

   { -- mini.align
      "echasnovski/mini.align",
      keys = {
         { mode = { "n", "x" }, "ga", desc = "Align" },
         { mode = { "n", "x" }, "gA", desc = "Align" },
      },
      opts = {},
   },
}
