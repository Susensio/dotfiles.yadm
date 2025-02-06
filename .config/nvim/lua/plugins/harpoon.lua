return {
   {
      "cbochs/grapple.nvim",
      cmd = "Grapple",
      init = function()
        vim.keymap.set("n", "<leader>m", "<cmd>Grapple toggle<cr>", { desc = "Grapple toggle tag" })
        vim.keymap.set("n", "<leader>M", "<cmd>Grapple toggle_tags<cr>", { desc = "Grapple open tags window" })
        -- vim.keymap.set("n", "<c-n>", "<cmd>Grapple cycle_tags next<cr>", { desc = "Grapple cycle next tag" })
        -- vim.keymap.set("n", "<c-p>", "<cmd>Grapple cycle_tags prev<cr>", { desc = "Grapple cycle previous tag" })
        vim.keymap.set("n", "<leader>1", "<cmd>Grapple select index=1<cr>", { desc = "Select first tag" })
        vim.keymap.set("n", "<leader>2", "<cmd>Grapple select index=2<cr>", { desc = "Select second tag" })
        vim.keymap.set("n", "<leader>3", "<cmd>Grapple select index=3<cr>", { desc = "Select third tag" })
        vim.keymap.set("n", "<leader>4", "<cmd>Grapple select index=4<cr>", { desc = "Select fourth tag" })
        vim.keymap.set("n", "<leader>5", "<cmd>Grapple select index=5<cr>", { desc = "Select fifth tag" })
      end,
      dependencies = {
         { "echasnovski/mini.icons" }
      },
      event = "VeryLazy",
   }
}
