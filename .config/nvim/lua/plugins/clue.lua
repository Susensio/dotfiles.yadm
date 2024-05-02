return {
  { -- mini.clue
    "echasnovski/mini.clue",
    event = "VeryLazy",
    -- keys = {
    --   { "<leader>", mode = { "n", "x" } },
    --   { "<C-x>",    mode = "i" },
    --   { "g",        mode = { "n", "x" } },
    --   { '"',        mode = { "n", "x" } },
    --   { "`",        mode = { "n", "x" } },
    --   { "<C-w>",    mode = "n" },
    --   { "z",        mode = { "n", "x" } },
    --   { "]",        mode = "n" },
    --   { "[",        mode = "n" },
    --   { "s",        mode = { "n", "x" } },
    -- },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        group = vim.api.nvim_create_augroup("MarkdownKeymapDescriptions", {clear=true}),
        callback = function()
          require("mini.clue").set_mapping_desc("n", "[[", "Section previous")
          require("mini.clue").set_mapping_desc("n", "]]", "Section next")
        end,
      })
    end,
    opts = {
      triggers = {
        -- Leader triggers
        { mode = "n", keys = "<Leader>" },
        { mode = "x", keys = "<Leader>" },

        -- Built-in completion
        { mode = "i", keys = "<C-x>" },

        -- `g` key
        { mode = "n", keys = "g" },
        { mode = "x", keys = "g" },

        -- Marks
        { mode = "n", keys = '"' },
        { mode = "n", keys = "`" },
        { mode = "x", keys = '"' },
        { mode = "x", keys = "`" },

        -- Registers
        -- { mode = "n", keys = """ },
        -- { mode = "x", keys = """ },
        -- { mode = "i", keys = "<C-r>" },
        -- { mode = "c", keys = "<C-r>" },

        -- Window commands
        { mode = "n", keys = "<C-w>" },

        -- `z` key
        { mode = "n", keys = "z" },
        { mode = "x", keys = "z" },

        -- bracketed
        { mode = "n", keys = "]" },
        { mode = "n", keys = "[" },

        -- -- surround
        -- { mode = "n", keys = "s" },
        -- { mode = "x", keys = "s" },
      },

      clues = {
        -- { mode = "n", keys = "<leader>f", desc = "+Find"},
        { mode = "n", keys = "<leader>u", desc = "+Toggle" },
        { mode = "n", keys = "cr", desc = "+Code Refactor" },

        { mode = "n", keys = "]]", desc = "Section next" },
        { mode = "n", keys = "[[", desc = "Section previous" },
        -- Spellcheck
        { mode = "n", keys = "]s", desc = "Spelling mistake next" },
        { mode = "n", keys = "[s", desc = "Spelling mistake previous" },
      },

      window = {
        config = {
          width = 50,
        },
      },
    },
    config = function(plugin, opts)
      local miniclue = require("mini.clue")
      opts.clues = vim.list_extend(opts.clues, {
        -- Enhance this by adding descriptions for <Leader> mapping groups
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        -- miniclue.gen_clues.registers({
        --   show_contents = true
        -- }),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),
      })
      miniclue.setup(opts)
    end,
  },

  { -- registers
    "tversteeg/registers.nvim",
    main = "registers",
    cmd = "Registers",
    keys = {
      { '"',    mode = { "n", "v" } },
      { "<C-R>", mode = "i" }
    },
    opts = function(plugin, _)
      local registers = require(plugin.main)
      local delay = 0.5
      return {
        bind_keys = {
          normal = registers.show_window({ delay = delay, mode = "motion" }),
          visual = registers.show_window({ delay = delay, mode = "motion" }),
          insert = registers.show_window({ delay = delay, mode = "insert" }),
        },
        window = {
          border = "single",
        },
        -- show_register_types = false,
        symbols = { -- add spacing between register name and value
          register_type_charwise = " ",
          register_type_linewise = " ",
          register_type_blockwise = " ",
        },
        -- do not preview register in buffer
        events = {
          on_register_highlighted = false,
        },
      }
    end,
  }
}
