return {
   { -- mini.ai
      "echasnovski/mini.ai",
      keys = {
         {"a", mode = {"o", "x"}},
         {"i", mode = {"o", "x"}},
      },
      dependencies = {
         "echasnovski/mini.extra",
      },
      enabled = true,
      opts = function(plugin)
         local ts = require("mini.ai").gen_spec.treesitter
         local extra = require("mini.extra").gen_ai_spec
         return {
            mappings = {
               around_next = "",
               inside_next = "",
               around_last = "",
               inside_last = "",
               goto_left = "",
               goto_right = "",
            },
            custom_textobjects = {
               m = ts({ a = "@function.outer", i = "@function.inner" }),
               f = ts({ a = "@call.outer", i = "@call.inner" }),
               o = ts({
                  a = { "@conditional.outer", "@loop.outer" },
                  i = { "@conditional.inner", "@loop.inner" },
               }),
               c = ts({ a = "@class.outer", i = "@class.inner" }),
               a = ts({ a = "@parameter.outer", i = "@parameter.inner" }),
               i = extra.indent(),
               g = extra.buffer(),
            },
            search_method = "cover_or_next",
            n_lines = 250,
         }
      end,
   },

}
