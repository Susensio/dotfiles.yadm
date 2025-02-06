return {
   {
      "neovim/nvim-lspconfig",
      optional = true,
      opts = {
         servers = {
            csharp_ls = {
               handlers = {
                  ["textDocument/definition"] = require('lazy-require').require_on_exported_call('csharpls_extended').handler,
                  ["textDocument/typeDefinition"] = require('lazy-require').require_on_exported_call('csharpls_extended').handler,
               },
               root_dir = function(fname)
                  return require('lspconfig.util').root_pattern({'*.csproj', '*.sln'})(fname)
               end,
            },
         }
      }
   },

   { -- csharpls-extended-lsp
      "Decodetalkers/csharpls-extended-lsp.nvim",
   },
}
