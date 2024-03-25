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
    -- config = function(plugin, opts)
    --   mc = require(plugin.name)
    --   mc.setup(opts)
    --   -- remap comment_visual for allowing textobject when no selection
    --   vim.keymap.set(
    --     "x",
    --     mc.config.mappings.comment_visual,
    --     function()
    --       if require("utils").is_visual_selection_empty() then
    --         return [[:<c-u>lua MiniComment.textobject()<CR>]]
    --       else
    --         return [[:<c-u>lua MiniComment.operator('visual')<cr>]]
    --       end
    --     end,
    --     { desc = "Comment selection", expr = true }
    --   )
    -- end,
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
