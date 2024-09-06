return {
   { -- outline
      "hedyhli/outline.nvim",
      cmd = { "Outline", "OutlineOpen" },
      init = function(plugin)
         require("utils.lsp").on_attach(
            function(client, buffer)
               vim.keymap.set(
                  "n",
                  "gO",
                  "<cmd>Outline<CR>",
                  { buffer = buffer, nowait = true, desc = "Code outline" }
               )
            end
         )
         require("utils.keymap").set_per_filetype(
            "Outline",
            "n",
            "q",
            function() require("outline").close() end,
            { nowait = true }
         )
      end,
      opts = {
         keymaps = {
            close = "<Esc>",
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
