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

   { -- neo-tree
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
         "nvim-lua/plenary.nvim",
         "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
         "MunifTanjim/nui.nvim",
      },
      cmd = "Neotree",
      keys = {
         {
            "<leader>e",
            function()
               require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd(), reveal = true })
            end,
            desc = "Explorer NeoTree",
         },
      },
      deactivate = function()
         vim.cmd([[Neotree close]])
      end,
      opts = {
         close_if_last_window = false,
         sources = {
            "filesystem",
            -- "buffers",
            -- "git_status"
         },
         open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
         filesystem = {
            bind_to_cwd = true,
            follow_current_file = {
               enabled = true,
               leave_dirs_open = true,
            },
            use_libuv_file_watcher = true,
         },
         window = {
            mappings = {
               ["-"] = "close_node",
               ["<space>"] = "none",
               ["\\"] = "open_vsplit",
               -- ["-"] = "open_split",
               ["Y"] = {
                  function(state)
                     local node = state.tree:get_node()
                     local path = node:get_id()
                     vim.fn.setreg("+", path, "c")
                  end,
                  desc = "Copy Path to Clipboard",
               },
            },
         },
         default_component_configs = {
            --    indent = {
            --       with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
            --       expander_collapsed = "",
            --       expander_expanded = "",
            --       expander_highlight = "NeoTreeExpander",
            --    },
            diagnostics = {
               symbols = require("utils.symbols").diagnostics,
            },
            git_status = {
               symbols = {
                  added     = "+",
                  deleted   = "-",
                  modified  = "~",
                  renamed   = "~",
               },
            },
         },
      },

      -- config = function(_, opts)
      --    local function on_move(data)
      --       LazyVim.lsp.on_rename(data.source, data.destination)
      --    end
      --
      --    local events = require("neo-tree.events")
      --    opts.event_handlers = opts.event_handlers or {}
      --    vim.list_extend(opts.event_handlers, {
      --       { event = events.FILE_MOVED, handler = on_move },
      --       { event = events.FILE_RENAMED, handler = on_move },
      --    })
      --    require("neo-tree").setup(opts)
      --    vim.api.nvim_create_autocmd("TermClose", {
      --       pattern = "*lazygit",
      --       callback = function()
      --          if package.loaded["neo-tree.sources.git_status"] then
      --             require("neo-tree.sources.git_status").refresh()
      --          end
      --       end,
      --    })
      -- end,
   },

   { -- oil
      'stevearc/oil.nvim',
      main = 'oil',
      enabled = true,
      lazy = false,  -- https://github.com/stevearc/oil.nvim/issues/300#issuecomment-2002968183
      dependencies = { "nvim-tree/nvim-web-devicons" },
      cmd = { "Oil" },
      init = function(plugin)
         vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
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
   },
}
