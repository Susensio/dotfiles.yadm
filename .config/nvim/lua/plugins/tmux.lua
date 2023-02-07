return {
  "numToStr/Navigator.nvim",
  config = true,
  init = function()
    vim.keymap.set( {"n", "t", "i"}, "<M-h>", function() require("Navigator").left() end )
    vim.keymap.set( {"n", "t", "i"}, "<M-l>", function() require("Navigator").right() end )
    vim.keymap.set( {"n", "t", "i"}, "<M-k>", function() require("Navigator").up() end )
    vim.keymap.set( {"n", "t", "i"}, "<M-j>", function() require("Navigator").down() end )
  end
}
