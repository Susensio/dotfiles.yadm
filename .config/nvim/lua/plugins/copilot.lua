return {
   {
      "zbirenbaum/copilot.lua",
      enabled = true,
      cmd = "Copilot",
      main = "copilot",
      event = "InsertEnter",
      init = function(_)
         vim.keymap.set(
            "n",
            "<leader>uc",
            function()
               require("copilot.suggestion").toggle_auto_trigger()
               require("utils").refresh_statusline()
               require("utils.log").toggle("copilot", vim.b.copilot_suggestion_auto_trigger)
            end,
            { desc = "Toggle Copilot" }
         )
         vim.keymap.set("i", "<C-j>", function()
            local suggestion = require("copilot.suggestion")
            if suggestion.is_visible() then
               suggestion.accept_line()
            else
               suggestion.next()
            end
         end, { desc = "Accept/trigger Copilot suggestion" })
      end,
      opts = {
         suggestion = {
            enabled = true,
            auto_trigger = false,
            keymap = {
               -- accept_word = '<C-e>',  -- Like end-of-word
               accept_line = '<C-l>',
               -- accept = '<C-j>',
            },

         },
         panel = {
            enabled = true,
         },
      },
   },
}
