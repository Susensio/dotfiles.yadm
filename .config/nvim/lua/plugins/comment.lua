return {
  -- comments
  { -- mini.comment
    "echasnovski/mini.comment",
    enabled = true,
    event = "VeryLazy",
    opts = {
      mappings = {
        comment_visual = "gc",
        textobject = "",
      },
    },
    config = function(plugin, opts)
      local mc = require("mini.comment")
      mc.setup(opts)
      if vim.fn.has('nvim-0.10') == 1 then
        vim.notify("MiniComment may not be needed anymore, builtin commenting has been merged in #28176", vim.log.levels.WARN)
      end

      -- remap comment_visual for allowing textobject when empty selection
      vim.keymap.set(
        "x",
        mc.config.mappings.comment_visual,
        function()
          if require("utils").is_visual_selection_empty() then
            return [[:<c-u>lua MiniComment.textobject()<CR>]]
          else
            return [[:<c-u>lua MiniComment.operator('visual')<cr>]]
          end
        end,
        { desc = "Comment selection", expr = true }
      )
    end,
  },

  { -- Comment
    "numToStr/Comment.nvim",
    enabled = false,
    event = "VeryLazy",
    opts = {
      mappings = { extra = true },
    },
  },
}
