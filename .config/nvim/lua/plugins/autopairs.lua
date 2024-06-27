return {
  { -- mini.pairs
    "echasnovski/mini.pairs",
    enabled = true,
    event = "InsertEnter",
    init = function(_)
      vim.keymap.set("n", "<leader>up",
        function()
          vim.b.minipairs_disable = not vim.b.minipairs_disable
          require("utils.log").toggle("auto pairs", vim.b.minipairs_disable)
        end,
        { desc = "Toggle autopairs" })

      -- Support removing the brackets with <C-w> and <C-u> (just like <BS>)
      -- https://github.com/echasnovski/mini.nvim/issues/246
      vim.keymap.set('i', '<C-w>', 'v:lua.MiniPairs.bs("\23")', { expr = true, replace_keycodes = false })
      vim.keymap.set('i', '<C-u>', 'v:lua.MiniPairs.bs("\21")', { expr = true, replace_keycodes = false })
    end,
    opts = {
      mappings = {
        -- modify default ones to not open if right to closing bracket
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\][^%)%w]' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\][^%]%w]' },
        -- keep curly brackets because of jinja
        -- ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\][^%}%w]' },

        -- [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        -- [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        -- ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

        -- add third quote without fourth, only close if continued by alphanumeric
        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\"][^%w]', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = "[^%a\\'][^%w]", register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\`][^%w]', register = { cr = false } },

        -- add double space inside other brackets
        -- https://github.com/echasnovski/mini.nvim/issues/10
        [' '] = { action = 'open', pair = '  ', neigh_pattern = '[%(%[{][%)%]}]' },
      },
      silent = true,
    },
  },

  { -- treesitter-endwise
    "RRethy/nvim-treesitter-endwise",
    enabled = false,
    init = function(plugin)
      require("utils.lazy").load_on_nested_events(plugin.name, { "LazyFile", "InsertEnter" })
    end,
    -- event = { "InsertEnter" },
    dependencies = { "nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = { enable = true },
      })
    end
  },

  { -- tabout
    "abecodes/tabout.nvim",
    enabled = false,
    event = "InsertEnter",
    dependencies = { "nvim-treesitter" },
    opts = {
      tabkey = "",
      backwards_tabkey = "",
      -- tabkey = "<Tab>",
      ignore_beginning = false,
      enable_backwards = false,
      ignore_beggining = false,
      completion = false,
    },
    config = function(plugin, opts)
      local tabout = require("tabout")
      tabout.setup(opts)

      -- require("supertab").add({
      --   desc = "Tabout",
      --   callback = tabout.tabout,
      --   priority = 10,
      --   when = true,
      --   halt = true,
      -- })
    end
  },

  { -- autopairs
    "windwp/nvim-autopairs",
    enabled = false,
    event = "InsertEnter",
    dependencies = { "nvim-treesitter" },
    opts = {
      check_ts = true,
      map_cr = true,
      enable_check_bracket_line = true,
      break_undo = false,
    },
    config = function(plugin, opts)
      require(plugin.name).setup(opts)

      local npairs = require('nvim-autopairs')
      local rule   = require('nvim-autopairs.rule')
      local cond   = require('nvim-autopairs.conds')

      -- Add spaces between parentheses
      -- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
      local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }

      npairs.add_rules {
        -- rule for a pair with left-side ' ' and right side ' '
        rule(' ', ' ')
          -- Pair will only occur if the conditional function returns true
          :with_pair(function(opts)
            -- We are checking if we are inserting a space in (), [], or {}
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2]
            }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          -- We only want to delete the pair of spaces when the cursor is as such: ( | )
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1] .. '  ' .. brackets[1][2],
              brackets[2][1] .. '  ' .. brackets[2][2],
              brackets[3][1] .. '  ' .. brackets[3][2]
            }, context)
          end)
      }
      -- For each pair of brackets we will add another rule
      for _, bracket in pairs(brackets) do
        npairs.add_rules {
          -- Each of these rules is for a pair with left-side '( ' and right-side ' )' for each bracket type
          rule(bracket[1] .. ' ', ' ' .. bracket[2])
            :with_pair(cond.none())
            :with_move(function(opts) return opts.char == bracket[2] end)
            :with_del(cond.none())
            :use_key(bracket[2])
            -- Removes the trailing whitespace that can occur without this
            :replace_map_cr(function(_) return '<C-c>2xi<CR><C-c>O' end)
        }
      end

    end,
  },
}
