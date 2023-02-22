return {
  -- comments
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    config = function(_, opts)
      require("mini.comment").setup(opts)
    end,
  },

  -- {
  --   "numToStr/Comment.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     mappings = { extra = false },
  --   },
  -- },

}

