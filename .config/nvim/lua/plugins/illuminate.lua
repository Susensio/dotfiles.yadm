return {
  { -- illuminate
    "RRethy/vim-illuminate",
    enabled = true,
    event = "LazyFile",
    opts = {
      delay = 300,
      -- large_file_cutoff = 2000,
      -- large_file_overrides = {
      --   providers = { "lsp" },
      -- },
      filetypes_denylist = {
        "Lazy",
      }
    },
    init = function()
      vim.keymap.set("n", "<C-n>", require("illuminate").goto_next_reference, { desc = "Next Reference" })
      vim.keymap.set("n", "<C-r>", require("illuminate").goto_prev_reference, { desc = "Prev Reference" })
      vim.keymap.set("n", "<leader>ui",
        function()
          require("illuminate").toggle()
          require("utils.log").toggle("illuminate", not require("illuminate").is_paused())
        end,
        { desc = "Toggle autopairs" })
    end,
    config = function(plugin, opts)
      require("illuminate").configure(opts)
    end,
  },
  -- {
  --   "echasnovski/mini.cursorword",
  --   enabled = false,
  --   event = "VeryLazy",
  --   opts = {
  --     delay = 1000,
  --   },
  -- },

  -- {
  --   "tzachar/local-highlight.nvim",
  --   enabled = false,
  --   lazy = false,
  --   config = true,
  -- },
  -- {
  --   "nvim-treesitter/nvim-treesitter-refactor",
  --   enabled = false,
  --   optional = true,
  --   event = { "CursorHold" },
  --   init = function()
  --     -- hook into plugin load event to modify the highlight_usages function and highlight the current node
  --     vim.api.nvim_create_autocmd("User", {
  --       pattern = "LazyLoad",
  --       callback = function(event)
  --         if event.data == "nvim-treesitter-refactor" then
  --           local highlight_usages = require("nvim-treesitter-refactor.highlight_definitions").highlight_usages
  --           require("nvim-treesitter-refactor.highlight_definitions").highlight_usages = function(bufnr)
  --             highlight_usages(bufnr)
  --             local ts_utils = require("nvim-treesitter.ts_utils")
  --             local node_at_point = ts_utils.get_node_at_cursor()
  --             if not node_at_point then
  --               return
  --             end
  --             if node_at_point:type() ~= "identifier" then
  --               return
  --             end
  --             local usage_namespace = vim.api.nvim_create_namespace("nvim-treesitter-usages")
  --             ts_utils.highlight_node(node_at_point, bufnr, usage_namespace, "TSCurrentNode")
  --           end
  --           -- delete the autocmd
  --           vim.api.nvim_del_augroup_by_name("NvimTreesitterUsagesLoaded")
  --         end
  --       end,
  --       group = vim.api.nvim_create_augroup("NvimTreesitterUsagesLoaded", {}),
  --     })
  --   end,
  --   opts = {
  --     highlight_definitions = {
  --       enable = true,
  --       attach = function(bufnr)
  --         require("nvim-treesitter-refactor.highlight_definitions").attach(bufnr)
  --         vim.b[bufnr].minicursorword_disable = true
  --       end,
  --       detach = function(bufnr)
  --         require("nvim-treesitter-refactor.highlight_definitions").detach(bufnr)
  --         vim.b[bufnr].minicursorword_disable = false
  --       end,
  --     },
  --   },
  -- },

  -- {
  --   dir = ".",
  --   enabled = false,
  --   name = "lsp_highlight",
  --   lazy = false,
  --   init = function()
  --     local grp = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })
  --     require("utils.lsp").on_attach(function(client, buffer)
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
  --         vim.b[buffer].minicursorword_disable = true
  --       end
  --     end)
  --   end,
  -- },

}
