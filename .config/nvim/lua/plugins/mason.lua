return {
   { -- mason
      "williamboman/mason.nvim",
      main = "mason",
      config = true,
      cmd = "Mason",
      build = ":MasonUpdate",
   },

   { -- mason-lspconfig
      "williamboman/mason-lspconfig.nvim",
      main = "mason-lspconfig",
      dependencies = {
         "williamboman/mason.nvim",
      },
      cmd = { "LspInstall", "LspUninstall", "PylspInstall" },
      opts = {
         automatic_installation = true,
      },
   },

   { -- mason-nvim-lint
      "rshkarin/mason-nvim-lint",
      init = function(plugin)
         require("utils.lazy").load_on_load(plugin, "nvim-lint")
      end,
      dependencies = {
         "williamboman/mason.nvim",
         "mfussenegger/nvim-lint",
      },
      opts = {
         automatic_installation = true,
      }
   },
}
