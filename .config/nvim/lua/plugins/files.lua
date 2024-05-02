return {
  { -- mini.files
    "echasnovski/mini.files",
    enabled = true,
    event = { "VimEnter */*,.*", "BufNew */*,.*" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      mappings = {
        go_in = '',
        go_in_plus = '<CR>',
        go_out = '-',
        go_out_plus = '<BS>',
        reset = '_',
      },
      windows = {
        preview = false
      },
      options = {
        -- use_as_default_explorer = true,
      },
    },
    config = function(plugin, opts)
      require(plugin.name).setup(opts)

      local show_dotfiles = true
      local filter_show = function(fs_entry)
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        require("mini.files").refresh({ content = { filter = new_filter } })
      end

      -- use :w to save filesystem change
      -- https://github.com/echasnovski/mini.nvim/issues/391
      vim.api.nvim_create_autocmd('User', {
        pattern = { 'MiniFilesBufferCreate', 'MiniFilesBufferUpdate' },
        callback = function(ev)
          local buf_id = ev.data.buf_id
          vim.schedule(function()
            vim.api.nvim_buf_set_option(buf_id, 'buftype', 'acwrite')
            vim.api.nvim_buf_set_name(buf_id, "MiniFiles_" .. buf_id)
            vim.api.nvim_create_autocmd('BufWriteCmd', {
              buffer = buf_id,
              callback = MiniFiles.synchronize,
            })

            -- Trigger LSP rename refactoring
            vim.api.nvim_create_autocmd("User", {
              pattern = "MiniFilesActionRename",
              callback = function(event)
                require("utils.lsp").on_rename(event.data.from, event.data.to)
              end,
            })

            -- close with <esc>
            vim.keymap.set("n", "<Esc>", MiniFiles.close, { buffer = buf_id })
            -- Move around without traversing the tree
            -- vim.keymap.set("n", "<C-h>", "h", { buffer = buf_id })
            -- vim.keymap.set("n", "<C-j>", "j", { buffer = buf_id })
            -- vim.keymap.set("n", "<C-k>", "k", { buffer = buf_id })
            -- vim.keymap.set("n", "<C-l>", "l", { buffer = buf_id })

            vim.keymap.set("n", "g.", toggle_dotfiles, {
              buffer = buf_id,
              desc = "Toggle hidden files"
            })
          end)

        end,
      })
    end,
    keys = {
      {
        mode = "n",
        "<leader>e",
        function()
          if not MiniFiles.close() then
            -- Handle not yet created folders
            local get_parent = vim.fs.dirname
            local exists = function(path) return vim.loop.fs_stat(path) ~= nil end
            local path = vim.api.nvim_buf_get_name(0)

            while not exists(path) do
              path = get_parent(path)
            end

            MiniFiles.open(path)
            MiniFiles.reveal_cwd()
          end
        end,
        desc = "Toggle file tree"
      },
    },
  },

  { -- oil
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = { "VimEnter */*,.*", "BufNew */*,.*" },
    cmd = { "Oil" },
    opts = {
      default_file_explorer = true,
      keymaps = {
        ["~"] = false,
      },
    },
  }
}
