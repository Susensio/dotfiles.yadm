return {
  { -- colorizer.lua
    "NvChad/nvim-colorizer.lua",
    enabled = true,
    -- event = "FileType",
    init = function(_)
      vim.keymap.set("n", "<leader>uv", function()
        local colorizer = require("colorizer")
        if colorizer.is_buffer_attached(0) then
          colorizer.detach_from_buffer(0)
        else
          colorizer.attach_to_buffer(0)
        end
        require("utils.log").toggle("colorizer", colorizer.is_buffer_attached(0) --[[@as boolean]])
      end, { desc = "Toggle colorizer" })
    end,
    opts = {
      filetypes = {
        "lua",
        "tmux",
      },
    },
  },
}
