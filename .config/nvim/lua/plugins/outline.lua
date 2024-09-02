return {
   {
      "hedyhli/outline.nvim",
      cmd = { "Outline", "OutlineOpen" },
      keys = { { "<leader>co", "<cmd>Outline<CR>", desc = "Code outline" } },
      opts = {
         keymaps = {
            hover_symbol = "K",
            toggle_preview = "<Tab>",
            code_actions = "ca",
            rename_symbol = "cr",
            fold = "h",
            unfold = "l",
            fold_toggle = "a",
            fold_all = "M",
            unfold_all = "R",
            fold_toggle_all = "A",
            fold_reset = "r",
         }
      },
   },
}
