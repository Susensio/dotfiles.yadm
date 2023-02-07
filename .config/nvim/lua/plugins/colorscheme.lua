return {
  {
    "tanvirtin/monokai.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local hl = vim.api.nvim_set_hl

      vim.cmd([[colorscheme monokai]])

      -- Maintain terminal background color
      hl(0, "Normal", { ctermfg="NONE" })

      -- Current line less intrusive
      hl(0, "CursorLine", { bg="#272727" })

      -- Line number
      hl(0, "LineNr", { fg="grey" })
    end,
  },
}
