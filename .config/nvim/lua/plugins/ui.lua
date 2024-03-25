return {
  { -- indent-blankline
    "lukas-reineke/indent-blankline.nvim",
    main = 'ibl',
    -- dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "LazyFile" },
    opts = {
      indent = {
        char = "│",
      },
      scope = {
        enabled = true,
        char = "┃",
        -- char = "│",
        show_start = false,
        show_end = false,
      },
      exclude = {
        filetypes = {
          "help",
          "starter",
          "lazy",
          "mason",
        },
      },
    },
  },

  {
    "echasnovski/mini.cursorword",
    enabled = false,
    lazy = false,
    config = true,
  },

  {
    "tzachar/local-highlight.nvim",
    enabled = false,
    lazy = false,
    config = true,
  },
  -- {
  --   dir = ".",
  --   enabled = false,
  --   name = "lsp_highlight",
  --   lazy = false,
  --   config = function()
  --     local grp = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })
  --     require("utils").lsp_on_attach(function(client, buffer)
  --       if client.server_capabilities["documentHighlightProvider"] then
  --         vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  --           buffer = buffer,
  --           group = grp,
  --           callback = vim.lsp.buf.document_highlight,
  --         })
  --         vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  --           buffer = buffer,
  --           group = grp,
  --           callback = vim.lsp.buf.clear_references,
  --         })
  --
  --         require("nvim-treesitter-refactor.highlight_definitions").detach(buffer)
  --       end
  --     end)
  --   end,
  -- },

  {
    "nvim-treesitter/nvim-treesitter-refactor",
    enabled = true,
    optional = true,
    event = { "CursorHold" },
    opts = {
      highlight_definitions = {
        enable = true,
      },
    },
  }
}
