return {
  { -- mini.files
    "echasnovski/mini.files",
    enabled = false,
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
        use_as_default_explorer = true,
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
    enabled = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Oil" },
    init = function(plugin)
      vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

      -- Lazy load
      -- https://github.com/kevinm6/nvim/blob/0c2d0fcb04be1f0837ae8918b46131f649cba775/lua/plugins/editor/oil.lua#L141
      if vim.fn.argc() == 1 then
         local argv = tostring(vim.fn.argv(0))
         local stat = vim.loop.fs_stat(argv)

         local remote_dir_args = vim.startswith(argv, "ssh") or
         vim.startswith(argv, "sftp") or
         vim.startswith(argv, "scp")

         if stat and stat.type == "directory" or remote_dir_args then
            require("lazy").load { plugins = { plugin.name } }
         end
      end
      if not require("lazy.core.config").plugins[plugin.name]._.loaded then
         vim.api.nvim_create_autocmd("BufNew", {
            callback = function()
               if vim.fn.isdirectory(vim.fn.expand("<afile>")) == 1 then
                  require("lazy").load { plugins = { "oil.nvim" } }
                  -- Once oil is loaded, we can delete this autocmd
                  return true
               end
            end,
            once = true,
         })
      end
    end,

    opts = {
      default_file_explorer = true,
      keymaps = {
        ["~"] = false,
      },
      columns = {
        "icon",
        -- "permissions",
      },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      view_options = {
        show_hidden = true,
        natural_order = true,
        is_always_hidden = function(name, _)
          return name == '..' or name == '.git'
        end,
      },
    },
  }
}
