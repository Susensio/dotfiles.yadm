return {
   { -- mini.clue
      "echasnovski/mini.clue",
      event = "VeryLazy",
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
            { mode = "n", keys = "`" },
            { mode = "x", keys = "`" },
            { mode = "n", keys = "'" },
            { mode = "x", keys = "'" },

            -- Registers
            { mode = "n", keys = '"' },
            { mode = "x", keys = '"' },
            { mode = "i", keys = "<C-r>" },
            { mode = "c", keys = "<C-r>" },

            -- Window commands
            { mode = "n", keys = "<C-w>" },

            -- `z` key
            { mode = "n", keys = "z" },
            { mode = "x", keys = "z" },

            -- bracketed
            { mode = "n", keys = "]" },
            { mode = "n", keys = "[" },
         },

         clues = {
            -- { mode = "n", keys = "<leader>f", desc = "+Find"},
            { mode = "n", keys = "<leader>u", desc = "+Toggle" },
            { mode = "n", keys = "<leader>c", desc = "+Code Refactor" },

            { mode = "n", keys = "]]", desc = "Section next" },
            { mode = "n", keys = "[[", desc = "Section previous" },
            -- Spellcheck
            { mode = "n", keys = "]s", desc = "Spelling mistake next" },
            { mode = "n", keys = "[s", desc = "Spelling mistake previous" },
         },

         window = {
            config = {
               width = 80,
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
            miniclue.gen_clues.registers({
               show_contents = true
            }),
            miniclue.gen_clues.windows(),
            miniclue.gen_clues.z(),
         })
         miniclue.setup(opts)
      end,
   },
}
