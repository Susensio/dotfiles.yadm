return {
   { -- indent-blankline
      "lukas-reineke/indent-blankline.nvim",
      main = 'ibl',
      -- dependencies = { "nvim-treesitter/nvim-treesitter" },
      event = { "LazyFile" },
      opts = {
         indent = {
            char = "│",
         },
         scope = {
            enabled = true,
            char = "┃",
            -- char = "│",
            show_start = false,
            show_end = false,
         },
         exclude = {
            filetypes = {
               "help",
               "starter",
               "lazy",
               "mason",
            },
         },
      },
   },
}
