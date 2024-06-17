return {
   { -- mini.diff
      "echasnovski/mini.diff",
      event = "LazyFile",
      init = function()
         vim.keymap.set(
            "n",
            "<leader>ug",
            function() require("mini.diff").toggle_overlay(0) end,
            { desc = "Toggle git overlay" }
         )
      end,
      opts = {
         view = {
            style = "sign",
            signs = {
               add = '▎',
               change = '▎',
               delete = '▁',
            },
         },
      },
   },

   { -- baredot
      "ejrichards/baredot.nvim",
      event = {
         "BufRead " .. vim.fn.expand("$XDG_CONFIG_HOME") .. "*",
         "BufRead " .. vim.fn.expand("$HOME") .. "bin/*",
      },
      ft = 'oil',
      opts = {
         git_dir = "$XDG_DATA_HOME/yadm/repo.git",
         git_work_tree = "$HOME",
      }
   },

}
