return {
   { -- illuminate
      "RRethy/vim-illuminate",
      enabled = true,
      event = "LazyFile",
      opts = {
         delay = 300,
         -- large_file_cutoff = 2000,
         -- large_file_overrides = {
         --   providers = { "lsp" },
         -- },
         filetypes_denylist = {
            "Lazy",
            "minifiles",
            "oil",
         }
      },
      init = function()
         -- vim.keymap.set("n", "<C-n>", require("illuminate").goto_next_reference, { desc = "Next Reference" })
         -- vim.keymap.set("n", "<C-p>", require("illuminate").goto_prev_reference, { desc = "Prev Reference" })
         vim.keymap.set("n", "<leader>uw",
            function()
               require("illuminate").toggle()
               require("utils.log").toggle("word illuminate", not require("illuminate").is_paused())
            end,
            { desc = "Toggle word illuminate" })
      end,
      config = function(plugin, opts)
         require("illuminate").configure(opts)
      end,
   },
}
