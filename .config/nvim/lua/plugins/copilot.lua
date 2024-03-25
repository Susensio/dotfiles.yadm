return {
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
    cmd = "Copilot",
    build = ":Copilot auth",
    main = "copilot",
    event = "InsertEnter",
    init = function(_)
      local suggestion = require("copilot.suggestion")

      -- local client = require("copilot.client")
      -- local api = require("copilot.api")
      -- local util = require("copilot.util")
      vim.keymap.set(
        "n",
        "<leader>uc",
        function()
          suggestion.toggle_auto_trigger()
          require("utils").refresh_statusline()
          require("utils.log").toggle("copilot", vim.b.copilot_suggestion_auto_trigger)
        end,
        { desc = "Toggle Copilot" }
      )
      vim.keymap.set("i", "<Tab>", function()
        -- not starting with a space
        if suggestion.is_visible() then
          local ns_id = vim.api.nvim_get_namespaces()["copilot.suggestion"]
          local suggested_text = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, 1, { details = true })[3].virt_text[1][1]
          if string.match(suggested_text, "^ ") == nil then
            suggestion.accept()
            return
          end
        end
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
      end, { desc = "Super Tab" })
    end,
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept_line = '<C-l>',
          accept = false
          --
        },
      },
      panel = {
        enabled = true,
      },
    },
    -- config = function(_, opts)
    --   local copilot = require("copilot")
    --   copilot.setup(opts)
    --
    --   local suggestion = require("copilot.suggestion")
    --   require("supertab").add({
    --     desc = "Accept copilot suggestion",
    --     when = suggestion.is_visible,
    --     callback = suggestion.accept,
    --     priority = 20,
    --     halt = true,
    --   })
    --
    -- end,
  },
}
