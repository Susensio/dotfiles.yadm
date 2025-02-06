return {
   {
      "neovim/nvim-lspconfig",
      optional = true,
      opts = {
         servers = {
            basedpyright = {
               settings = {
                  basedpyright = {
                     diableOrganizeImports = true,
                     analysis = {
                        typeCheckingMode = "standard",
                        autoImportCompletions = true,
                        -- ignore = { '*' },
                     },
                  },
                  python = {
                  },
               }
            },
            ruff = {
               on_attach = function(client, bufnr)
                  client.server_capabilities.hoverProvider = false
                  -- client.server_capabilities.codeActionProvider = false
                  vim.keymap.set(
                     "n",
                     "<leader>co",
                     require("utils.lsp").code_action["source.organizeImports"],
                     {
                        buffer = bufnr,
                        desc = "Organize Imports",
                     }
                  )
               end,
               init_options = {
                  settings = {
                     lineLength = 120,
                     lint = {
                        select = {
                           "E",   -- pycodestyle errors
                           "W",   -- pycodestyle warnings
                           "F",   -- pyflakes
                           "B",   -- bugbear: security
                           "S",   -- bandit: security
                           "A",   -- keyword clobber
                           "UP",  -- better syntax
                           "N",   -- naming
                           "SIM", -- simplify
                           "I",   -- import sort
                           "PT",  -- pytest
                           "RUF", -- ruff specific
                           "C90", -- complexity
                           "C4",  -- comprehensions
                           "FBT", -- boolean gotchas
                           "BLE", -- exception
                        },
                        ignore = {
                           -- Prevent duplicates with basedpyright
                           "ANN",
                           "B018",
                           "F821",
                           "F401",
                           "PLC0414",
                           "RUF013",
                           "RUF016",
                           -- Other rules
                           -- "C408",  -- Unnecessary dict call
                        },
                     },
                     fixAll = false,
                  },
               },
            },
         },
      },
   },

   {
      "mfussenegger/nvim-lint",
      optional = true,
      opts = {
         linters_by_ft = {
            python = {
               "mypy",
               "vulture",
            },
         },
      }
   }
}
