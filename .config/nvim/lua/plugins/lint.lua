return {
   {
      "mfussenegger/nvim-lint",
      enabled = true,
      event = "LazyFile",
      opts = {
         -- Event to trigger linters
         events = { "BufWritePost", "InsertLeave", "BufEnter" },
         linters_by_ft = {},
      },
      config = function(plugin, opts)
         local lint = require("lint")

         lint.linters_by_ft = opts.linters_by_ft

         -- local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
         --
         -- vim.api.nvim_create_autocmd(opts.events, {
         --    group = lint_augroup,
         --    callback = function()
         --       lint.try_lint()
         --    end,
         -- })
      end,
   },
}
