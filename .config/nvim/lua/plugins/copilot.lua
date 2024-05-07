return {
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
    cmd = "Copilot",
    build = ":Copilot auth",
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

      vim.keymap.set("i", "<Tab>", function()
        local suggestion = require("copilot.suggestion")
        -- not starting with a space
        if suggestion.is_visible() then
          local ns_id = vim.api.nvim_get_namespaces()["copilot.suggestion"]
          local suggested_text = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, 1, { details = true })[3].virt_text[1][1]
          local starts_with_spaces = string.match(suggested_text, "^  +")
          if starts_with_spaces ~= nil then
            -- insert those spaces
            vim.api.nvim_feedkeys(starts_with_spaces, "n", true)
          else
            suggestion.accept()
          end
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Super Tab" })
    end,
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept_word = '<C-l>',
          accept_line = '<C-L>',
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
