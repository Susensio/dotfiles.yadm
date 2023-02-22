return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = {
      "kyazdani42/nvim-web-devicons",
      "RRethy/nvim-base16",
    },
    opts = {
      options = {
        icons_enabled = true,
        theme = "base16",
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        disabled_filetypes = { "starter", "lazy" },
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    },
    config = function(_, opts)
      vim.opt.showmode = false
      require("lualine").setup(opts)
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      char = "⎸",
      context_char = "⎸",
      show_trailing_blankline_indent = false,
      show_current_context = true,
      show_current_context_start = false,

      indent_blankline_strict_tabs = true,
      show_end_of_line = true,

      use_treesitter = true,
      use_treesitter_scope = false,

      filetype_exclude = {
        "help",
        "starter",
        "lazy",
      },
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    enabled = true,
    event = "FileType",
    opts = {
      filetypes = {
        "lua",
        "tmux",
      },
    },
  },
}
