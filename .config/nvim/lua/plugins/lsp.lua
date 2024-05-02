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
        "pylsp-rope",
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
              pylsp_rope = {
                rename = {
                  enabled = true,
                },
              },
            },
            configurationSources = { "flake8" },
          },
        },
      })
    end
  },
}
