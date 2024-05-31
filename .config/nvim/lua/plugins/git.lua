return {
  { -- mini.diff
    "echasnovski/mini.diff",
    event = "LazyFile",
    init = function()
      vim.keymap.set(
        "n",
        "<leader>ug",
        function() require("mini.diff").toggle_overlay() end,
        { desc = "Toggle git overlay" }
      )
    end,
    opts = {
      view = {
        style = "sign",
        signs = {
          add = '▎',
          change = '▎',
          delete = '🭻'
        },
      },
    },
  }
}
