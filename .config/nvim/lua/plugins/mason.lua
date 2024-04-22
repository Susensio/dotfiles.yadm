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
}
