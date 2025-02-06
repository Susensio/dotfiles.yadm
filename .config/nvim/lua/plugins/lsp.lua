return {
   { -- lspconfig
      "neovim/nvim-lspconfig",
      main = "lspconfig",
      event = "LazyFile",
      dependencies = {
         "williamboman/mason-lspconfig.nvim",
      },
      cmd = { "LspInfo", "LspStart", "LspStop", "LspRestart" },
      opts = {
         servers = {
         }
      },
      config = function(plugin, opts)
         local lsp = require(plugin.main)

         for server, server_opts in pairs(opts.servers) do
            lsp[server].setup(server_opts)
         end
      end
   },

   { -- inc-rename
      "smjonas/inc-rename.nvim",
      event = "LazyFile",
      cmd = "IncRename",
      config = true,
   },
}
