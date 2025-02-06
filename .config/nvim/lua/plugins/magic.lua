return {
   { -- guess-indent
      "nmac427/guess-indent.nvim",
      config = true,
      event = "LazyFile",
      cmd = "GuessIndent",
   },

   { -- magic-bang
      "susensio/magic-bang.nvim",
      config = true,
      dev = false,
      event = "BufNewFile",
      cmd = "Bang",
   },

   { --bigfile
      "pteroctopus/faster.nvim",
      lazy = false,
      opts = {
         behaviours = {
            bigfile = {
               filesize = 5,
            },
         },
      },
   },

   { --spellfile
      "cuducos/spellfile.nvim",
      event = "SpellFileMissing",
      config = function()
         require("spellfile_nvim").load_file("es_es")
      end,
      -- lazy = false,
   }

   -- { -- mini.trailspace
   --   "echasnovski/mini.trailspace",
   --   enabled = true,
   --   event = { "BufReadPost", "BufNewFile" },
   --   config = function(plugin, opts)
   --     require(plugin.name).setup(opts)
   --
   --     vim.api.nvim_create_autocmd("BufWritePre", {
   --       desc = "Remove trailing whitespace on save",
   --       pattern = "*",
   --       group = "MiniTrailspace",
   --       callback = function()
   --         MiniTrailspace.trim()
   --         MiniTrailspace.trim_last_lines()
   --       end,
   --     })
   --   end,
   -- },

   -- { --
   --   "axkirillov/hbac.nvim",
   --   event = "BufLeave",
   --   opts = {
   --     -- autoclose = true,
   --     threshold = 5, -- aggressive
   --     -- close_command = function(bufnr)
   --       -- vim.api.nvim_buf_delete(bufnr, {})
   --     -- end,
   --     -- close_buffers_with_windows = false,
   --   }
   -- },
}
