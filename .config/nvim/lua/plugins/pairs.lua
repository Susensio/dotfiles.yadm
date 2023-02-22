return {
  { -- Surround commands with `sa` `sc` `sd`
    "echasnovski/mini.surround",
    event = "VeryLazy",
    config = function(_, opts)
      require("mini.surround").setup(opts)
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter" },
    opts = {
      check_ts = true,
      map_cr = true,
    },
    config = function(plugin, opts)
      require(plugin.name).setup(opts)

      local npairs = require'nvim-autopairs'
      local rule   = require'nvim-autopairs.rule'

      -- Add spaces between parentheses
      -- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
      local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
      npairs.add_rules {
        rule(' ', ' ')
          :with_pair(function (opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1]..brackets[1][2],
              brackets[2][1]..brackets[2][2],
              brackets[3][1]..brackets[3][2],
            }, pair)
          end)
      }
      for _,bracket in pairs(brackets) do
        npairs.add_rules {
          rule(bracket[1]..' ', ' '..bracket[2])
            :with_pair(function() return false end)
            :with_move(function(opts)
              return opts.prev_char:match('.%'..bracket[2]) ~= nil
            end)
            :use_key(bracket[2])
        }
      end

    end,
  },

  { -- Tab out of pairs
    "abecodes/tabout.nvim",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter" },
    config = true,
  },

  { -- Add `end` after function
    "RRethy/nvim-treesitter-endwise",
    enabled = false,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter"
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = { enable = true },
      })
    end
  },

}
