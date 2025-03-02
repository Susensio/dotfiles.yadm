local hl = require("utils").highlight

return {
   { -- statuscol
      "luukvbaal/statuscol.nvim",
      enabled = true,
      event = "VeryLazy",
      lazy = false,
      init = function()
      end,
      opts = function(plugin, opts)
         local builtin = require("statuscol.builtin")
         return {
            relculright = false,
            segments = {
               {
                  text = { "%s" },
                  click = "v:lua.ScSa",
               },

               {
                  text = { builtin.foldfunc, hl("FoldColumn") " " },
                  hl = "FoldColumn",
                  click = "v:lua.ScFa",
               },
               {
                  text = { builtin.lnumfunc, " " },
                  condition = { true, builtin.not_empty },
                  click = "v:lua.ScLa",
               },
            },
            ft_ignore = {
               "neo-tree",
               "starter",
               "Outline",
            },
         }
      end,
   },
}
