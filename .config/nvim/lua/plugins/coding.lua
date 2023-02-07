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

  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    config = function(_, opts)
      require("mini.surround").setup(opts)
    end,
  },

  -- {
  --   "echasnovski/mini.pairs",
  --   event = "VeryLazy",
  --   config = function(_, opts)
  --     require("mini.pairs").setup(opts)
  --   end,
  -- },

  {
    "windwp/nvim-autopairs",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter" },
    opts = {
      check_ts = true,
      map_cr = true,
    },
  },
}
