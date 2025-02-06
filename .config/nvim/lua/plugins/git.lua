return {
   { -- mini.git
      "echasnovski/mini-git",
      main = "mini.git",
      event = "LazyFile",
      opts = {},
   },

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

   { -- blame
      "FabijanZulj/blame.nvim",
      -- event = "LazyFile",
      cmd = "BlameToggle",
      init = function()
         vim.keymap.set(
            "n",
            "<leader>ub",
            function()
               local blame = require("blame")
               local log = require("utils.log")
               vim.cmd("BlameToggle window")
               log.toggle("git blame", blame.is_open() == true)
            end,
            { desc = "Toggle git blame" }
         )
      end,
      opts = {
         mappings = {
            commit_info = "K",
         }
      }
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
         disable_pattern = "^%.git$",
      }
   },

   { -- diffview
      "sindrets/diffview.nvim",
      -- event = "LazyFile",
      cmd = {
         "DiffviewOpen",
         "DiffviewFileHistory",
      },
      opts = {
         view = {
            merge_tool = {
               layout = "diff4_mixed",
            },
         },
      },
   },
}
