return {
   { -- tmux
      "aserowy/tmux.nvim",
      enabled = true,
      config = true,
      init = function(plugin)
         -- navigation
         vim.keymap.set(
            { "", "!" },
            "<M-h>",
            function()
               vim.cmd.stopinsert()
               require("tmux").move_left()
            end,
            { desc = "Move to left split" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-l>",
            function()
               vim.cmd.stopinsert()
               require("tmux").move_right()
            end,
            { desc = "Move to right split" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-k>",
            function()
               vim.cmd.stopinsert()
               require("tmux").move_top()
            end,
            { desc = "Move to top split" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-j>",
            function()
               vim.cmd.stopinsert()
               require("tmux").move_bottom()
            end,
            { desc = "Move to bottom split" }
         )

         -- resize
         vim.keymap.set(
            { "", "!" },
            "<M-C-h>",
            function() require("tmux").resize_left() end,
            { desc = "Resize towards left" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-C-l>",
            function() require("tmux").resize_right() end,
            { desc = "Resize towards right" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-C-k>",
            function() require("tmux").resize_top() end,
            { desc = "Resize towards top" }
         )
         vim.keymap.set(
            { "", "!" },
            "<M-C-j>",
            function() require("tmux").resize_bottom() end,
            { desc = "Resize towards bottom" }
         )
      end,
      opts = {
         copy_sync = {
            enable = false,
         },
         navigation = {
            cycle_navigation = false,
            enable_default_keybindings = false,
         },
         resize = {
            enable_default_keybindings = false,
            resize_step_x = 4,
            resize_step_y = 2,
         }
      }
   }
}
