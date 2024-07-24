return {
  { -- treesitter
    "nvim-treesitter/nvim-treesitter",
    version = false, -- last release is way too old and doesn't work on Windows
    build = ":TSUpdate",
    event = "LazyFile",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    init = function(plugin)
      -- Copied from LazyVim, performance improvement
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    keys = {
      { "<CR>", desc = "Increment selection" },
      { "<BS>", desc = "Shrink selection", mode = "x" },
    },
    opts = {
      -- ensure_installed = "all",
      ensure_installed =  {
        "bash",
        "c",
        "comment",
        "dockerfile",
        "fish",
        "gitcommit",
        "gitignore",
        "lua",
        "python",
        "query",
        "regex",
        "vim",
        "vimdoc",
        "yaml",
      },
      -- auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = { "dockerfile" },
      },
      indent = {
        enable = true,
        -- disable = { "yaml" },
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          scope_incremental = "<S-CR>",
          node_decremental = "<BS>",
        },
        is_supported = function()
          -- disable in command window
          local mode = vim.api.nvim_get_mode().mode
          return mode ~= "c"
        end
      },
      -- autotag = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  { -- treesitter-textobjects
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function(plugin)
      require("utils.lazy").load_on_load(plugin, "nvim-treesitter")
    end,
    opts = {
      -- textobjects defined with mini.ai plugin in ./targets.lua
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          -- ["k"]
        }
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = { query = "@function.outer", desc = "Function next" },
          ["]f"] = { query = "@call.outer", desc = "Call next" },
          ["]o"] = { query = "@loop.outer", desc = "Loop next" },
          ["]c"] = { query = "@class.outer", desc = "Class next" },
          ["]a"] = { query = "@parameter.inner", desc = "Argument next" },
          ["]gc"] = { query = "@comment.outer", desc = "Comment next" },
        },
        goto_previous_start = {
          ["[m"] = { query = "@function.outer", desc = "Function previous" },
          ["[f"] = { query = "@call.outer", desc = "Call previous" },
          ["[o"] = { query = "@loop.outer", desc = "Loop previous" },
          ["[c"] = { query = "@class.outer", desc = "Class previous" },
          ["[a"] = { query = "@parameter.inner", desc = "Argument previous" },
          ["[gc"] = { query = "@comment.outer", desc = "Comment previous" },
        },
      }
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup({ textobjects = opts })
    end
  },

  { -- treesitter-context
    "nvim-treesitter/nvim-treesitter-context",
    main = "treesitter-context",
    enabled = true,
    init = function(plugin)
      require("utils.lazy").load_on_load(plugin, "nvim-treesitter")
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts =  {
      line_numbers = true,
      is_supported = function()
        -- disable in command window
        local mode = vim.api.nvim_get_mode().mode
        return mode ~= "c"
      end
    },
    config = function(plugin, opts)
      require(plugin.main).setup(opts)
      require("utils").highlight_update(
        0,
        "TreesitterContextBottom",
        { underline = true }
      )
      vim.keymap.set("n", "<leader>uh",
        function()
          local tsc = require("treesitter-context")
          tsc.toggle()
          require("utils.log").toggle("treesitter context", tsc.enabled())
        end,
        { desc = "Toggle context header" })
    end,
  },

  { -- treesitter-refactor (just in case LSP is not available)
    "nvim-treesitter/nvim-treesitter-refactor",
    enabled = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function(plugin)
      require("utils.lazy").load_on_load(plugin, "nvim-treesitter")
    end,
    -- keys = {
    --   { "crn", desc = "Rename (TS)" },
    --   { "gd", desc = "Goto Definition (TS)" },
    -- },
    opts = {
      smart_rename = {
        enable = true,
        keymaps = {
          smart_rename = "crn",
        },
      },
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = "gd",
          list_definitions = false,
          list_definitions_toc = false,
          goto_next_usage = false,
          goto_previous_usage = false,
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup({ refactor = opts })
    end,
  }

  -- { -- treesitter-textsubjects
  --   "RRethy/nvim-treesitter-textsubjects",
  --   enabled = false,
  --   event = "LazyFile",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   opts = {
  --     enable = true,
  --     prev_selection = ',', -- (Optional) keymap to select the previous selection
  --     keymaps = {
  --       ['.'] = 'textsubjects-smart',
  --       [';'] = 'textsubjects-container-outer',
  --       ['i;'] = 'textsubjects-container-inner',
  --     },
  --   },
  --   config = function(_, opts)
  --     require("nvim-treesitter.configs").setup({ textsubjects = opts })
  --   end
  -- },

}
