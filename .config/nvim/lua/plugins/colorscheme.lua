local function fix_monokai()
  -- Using an autocmd
  -- https://github.com/folke/lazy.nvim/issues/488#issuecomment-1421518511
  local hl = vim.api.nvim_set_hl
  local grp = vim.api.nvim_create_augroup("FixMonokai", { clear = true })

  vim.api.nvim_create_autocmd(
    "ColorScheme",
    {
      pattern = "*monokai",
      callback = function()
        -- maintain terminal background color
        hl(0, "Normal", { ctermfg="none" })

        -- current line less intrusive
        hl(0, "CursorLine", { bg="#272727" })
        hl(0, "CursorColumn", { bg="#272727" })

        -- line number
        hl(0, "LineNR", { fg="grey" })
      end,
      group = grp,
      desc = "Fix background and other colors for monokai colorscheme",
    }
  )
end

return {
  {
    "tanvirtin/monokai.nvim",
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function()
      fix_monokai()
      vim.cmd.colorscheme("monokai")
    end,
  },

  { -- Used for lualine
    "RRethy/nvim-base16",
    enabled = true,
    config = function()
      vim.env.BASE16_THEME = "monokai"
    end,
  },
}
