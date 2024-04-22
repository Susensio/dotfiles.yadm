local on_attach = require("utils.lsp").on_attach

-- Set lsp float window name
on_attach(function()
  local open_floating_preview = vim.lsp.util.open_floating_preview
  vim.lsp.util.open_floating_preview = function(...)
    local bufnr, winnr = open_floating_preview(...)
    vim.api.nvim_buf_set_name(bufnr, "LSP preview")
    vim.keymap.set("n", "<Esc>", function()
      vim.api.nvim_win_close(winnr, true)
    end, { buffer = bufnr })
    return bufnr, winnr
  end
end, { once = true, desc = "Set lsp float window name" })

-- TODO: use native mason when 2.0 is released
local function pylsp_add_plugins(plugins)

  require("mason-registry"):on("package:install:success", function(pkg)
    if pkg.name ~= "python-lsp-server" then
      return
    end

    vim.schedule(function()
      require("mason-core.notify")("Installing pylsp plugins...")
      vim.cmd.PylspInstall(plugins)
    end)
  end)
end

return {
  { -- lspconfig
    "neovim/nvim-lspconfig",
    main = "lspconfig",
    event = "LazyFile",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      { "folke/neodev.nvim", config = true }
    },
    cmd = { "LspInfo", "LspStart", "LspStop", "LspRestart" },
    config = function(plugin, opts)
      local lsp = require(plugin.main)

      -- Set up servers
      lsp.bashls.setup({})

      lsp.lua_ls.setup({
        on_init = function(client)
          -- Fix comment tags conflict
          vim.api.nvim_set_hl(0, '@lsp.type.comment.lua', {})
        end
      })

      pylsp_add_plugins({
        "python-lsp-isort",
        "flake8-pyproject",
        "flake8-bugbear",
        "flake8-builtins",
        "pep8-naming",
      })
      lsp.pylsp.setup({
        -- These should be automatically installed by mason-lspconfig
        plugins = {
          "flake8-pyproject",
          "python-lsp-isort",
        },
        settings = {
          pylsp = {
            plugins = {
              flake8 = {
                enabled = true,
              },
              pycodestyle = {
                enabled = false,
              },
              mccabe = {
                enabled = false,
              },
              pyflakes = {
                enabled = false,
              },

              yapf = {
                enabled = false,
              },
              autopep8 = {
                enabled = true,
              },

              isort = {
                enabled = true,
              },
              rope_autoimport = {
                enabled = true,
              },
            },
            configurationSources = { "flake8" },
          },
        },
      })
    end
  },

  -- { -- mason-lspconfig
  --   "williamboman/mason-lspconfig.nvim",
  --   dependencies = {
  --     "williamboman/mason.nvim",
  --     "neovim/nvim-lspconfig",
  --     { "folke/neodev.nvim", config = true }
  --   },
  --   event = "LazyFile",
  --   cmd = { "LspInstall", "LspUninstall" },
  --   opts = {
  --     ensure_installed = {
  --       "lua_ls",
  --       "bashls",
  --       "pylsp",
  --     },
  --     -- this option is for servers set up by nvim-lspconfig directly
  --     -- automatic_installation = true,
  --     handlers = {
  --       -- Automatic set up servers
  --       function(server_name) require("lspconfig")[server_name].setup({}) end,
  --       -- Custom config per servers
  --       lua_ls = function()
  --         require("lspconfig").lua_ls.setup({})
  --         -- Fixes comment tags conflict
  --         -- https://github.com/stsewd/tree-sitter-comment/issues/22
  --         vim.api.nvim_set_hl(0, '@lsp.type.comment.lua', {})
  --
  --         -- This was instead of neodev
  --         -- require("lspconfig").lua_ls.setup({
  --         --   settings = {
  --         --     Lua = { -- this is an alternative to neodev
  --         --       runtime = {version = 'LuaJIT'},
  --         --       diagnostics = {globals = {'vim'},},
  --         --       workspace = {library = {
  --         --         vim.env.VIMRUNTIME .. '/lua',
  --         --         vim.fn.stdpath("config") .. '/lua',
  --         --       }}
  --         --     }
  --         --   }
  --         -- })
  --       end
  --     },
  --   },
  -- },

  -- { -- mason-null-ls
  --   "jay-babu/mason-null-ls.nvim",
  --   event = "LazyFile",
  --   dependencies = {
  --     "williamboman/mason.nvim",
  --     { "nvimtools/none-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  --   },
  --   opts = {
  --     ensure_installed = {
  --       "mypy",
  --       "shellcheck",
  --       -- "stylua",
  --     },
  --     handlers = {
  --       -- automatic set up servers
  --     },
  --   }
  -- }


  -- {
  --   "neovim/nvim-lspconfig",
  --   dependencies = {
  --     "williamboman/mason.nvim",
  --     "williamboman/mason-lspconfig.nvim",
  --   },
  --   cmd = { "LspInfo", "LspStart", "LspStop", "LspRestart" },
  --   config = true,
  -- },
}
