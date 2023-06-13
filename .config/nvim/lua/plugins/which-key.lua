return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      vim.o.timeout = true
      vim.o.timeoutlen = 800
      require("which-key").setup({
        window = {
          winblend = 20,
        },
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      })
    end,
  },
}
