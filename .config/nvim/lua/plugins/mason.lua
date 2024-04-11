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
    },
    cmd = { "LspInstall", "LspUninstall", "PylspInstall" },
    opts = {
      automatic_installation = true,
    },
  },
}
