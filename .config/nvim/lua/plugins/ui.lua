return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    opts = {
      char = "|",
      -- char = "▏",
      show_current_context = true,
      space_char_blankline = " ",
      indent_blankline_strict_tabs = true,
      show_end_of_line = true,
      use_treesitter = true,
    },
  },
}
