return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      { "<CR>", desc = "Increment selection" },
      { "<BS>", desc = "Shrink selection", mode = "x" },
    },
    opts = {
      -- ensure_installed = "all",
      ensure_installed =  {
        "bash", "fish",
        "dockerfile", "regex",
        -- "gitignore", "gitcommit",
        "vimdoc", "comment",
        "python", "lua", "vim",
        "yaml",
      },
      sync_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
        -- disable = { "fish" },
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          node_decremental = "<BS>",
          scope_incremental = nil,
        },
      },
      -- autotag = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "RRethy/nvim-treesitter-textsubjects",
    enabled = false,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textsubjects = {
          enable = true,
          prev_selection = ',', -- (Optional) keymap to select the previous selection
          keymaps = {
            ['.'] = 'textsubjects-smart',
            [';'] = 'textsubjects-container-outer',
            ['i;'] = 'textsubjects-container-inner',
          },
        },
      })
    end
  },
}
