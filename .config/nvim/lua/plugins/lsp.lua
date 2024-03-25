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

return {
  { -- mason
    "williamboman/mason.nvim",
    config = true,
    cmd = "Mason",
    build = ":MasonUpdate",
  },

  { -- mason-lspconfig
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      { "folke/neodev.nvim", config = true }
    },
    event = "LazyFile",
    cmd = { "LspInstall", "LspUninstall" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "bashls",
        "pylsp",
      },
      -- this option is for servers set up by nvim-lspconfig directly
      -- automatic_installation = true,
      handlers = {
        -- Automatic set up servers
        function(server_name) require("lspconfig")[server_name].setup({}) end,
        -- Custom config per servers
        lua_ls = function()
          require("lspconfig").lua_ls.setup({})
          -- Fixes comment tags conflict
          -- https://github.com/stsewd/tree-sitter-comment/issues/22
          vim.api.nvim_set_hl(0, '@lsp.type.comment.lua', {})

          -- This was instead of neodev
          -- require("lspconfig").lua_ls.setup({
          --   settings = {
          --     Lua = { -- this is an alternative to neodev
          --       runtime = {version = 'LuaJIT'},
          --       diagnostics = {globals = {'vim'},},
          --       workspace = {library = {
          --         vim.env.VIMRUNTIME .. '/lua',
          --         vim.fn.stdpath("config") .. '/lua',
          --       }}
          --     }
          --   }
          -- })
        end
      },
    },
  },

  { -- mason-null-ls
    "jay-babu/mason-null-ls.nvim",
    event = "LazyFile",
    dependencies = {
      "williamboman/mason.nvim",
      { "nvimtools/none-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = {
      ensure_installed = {
        "mypy",
        "shellcheck",
        -- "stylua",
      },
      handlers = {
      }, -- automatic set up servers
    }
  }


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
