return {
  { -- Navigator
    "numToStr/Navigator.nvim",
    enabled = false,
    -- event = "VimEnter",
    config = true,
    init = function(plugin)
      vim.keymap.set(
        { "", "!", "o"},
        "<M-h>",
        function() require("Navigator").left() end,
        { desc = "Move to left split" }
      )
      vim.keymap.set(
        { "", "!", "o"},
        "<M-l>",
        function() require("Navigator").right() end,
        { desc = "Move to right split" }
      )
      vim.keymap.set(
        { "", "!", "o"},
        "<M-k>",
        function() require("Navigator").up() end,
        { desc = "Move to up split" }
      )
      vim.keymap.set(
        { "", "!", "o"},
        "<M-j>",
        function() require("Navigator").down() end,
        { desc = "Move to down split" }
      )
    end,
  },

  { -- tmux
    "aserowy/tmux.nvim",
    enabled = true,
    config = true,
    init = function(plugin)
      -- navigation
      vim.keymap.set(
        { "", "!" },
        "<M-h>",
        function() require("tmux").move_left() end,
        { desc = "Move to left split" }
      )
      vim.keymap.set(
        { "", "!" },
        "<M-l>",
        function() require("tmux").move_right() end,
        { desc = "Move to right split" }
      )
      vim.keymap.set(
        { "", "!" },
        "<M-k>",
        function() require("tmux").move_top() end,
        { desc = "Move to top split" }
      )
      vim.keymap.set(
        { "", "!" },
        "<M-j>",
        function() require("tmux").move_bottom() end,
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
