return {
  { -- Infer indent in current file
    "nmac427/guess-indent.nvim",
    config = true,
    event = { "BufReadPost", "BufNewFile" },
    cmd = "GuessIndent",
  },

  { -- Open with cursor in last place
    "ethanholz/nvim-lastplace",
    config = true,
    event = { "BufReadPost", "BufNewFile" },
  },

  { -- Automatic shebang
    "susensio/magic-bang.nvim",
    config = true,
    event = "BufNewFile",
    cmd = "Bang",
  },
}
