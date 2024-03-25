return {
  { -- tree.lua
    "nvim-tree/nvim-tree.lua",
    enabled = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    init = function()
      vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = function(data)
        -- buffer is a directory
        local directory = vim.fn.isdirectory(data.file) == 1

        if not directory then
          return
        end

        -- change to the directory
        vim.cmd.cd(data.file)

        -- open the tree
        require("nvim-tree.api").tree.open()
      end
      })
    end,
    opts = {
      hijack_unnamed_buffer_when_opening = true,
      disable_netrw = true,
      hijack_cursor = true,
      renderer = {
        add_trailing = false,
        highlight_modified = "name",
        highlight_opened_files = "name",
        icons = {
          show = {
            modified = false,
            folder_arrow = false,
          },
        },
        indent_markers = {
          enable = true,
          -- inline_arrows = false,
          icons = {
            item = "├",
          },
        },
      },
      update_focused_file = {
        enable = true,
      },
      modified = {
        enable = true,
        show_on_dirs = false,
      },
      live_filter = {
        always_show_folders = false,
      },
      diagnostics = {
        enable = true,
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      -- Auto close
      vim.api.nvim_create_autocmd({"QuitPre"}, {
        callback = function() vim.cmd("NvimTreeClose") end,
      })

      local hl_update = require("utils").highlight_update
      hl_update(0, "NvimTreeModifiedFile", { italic = true })
      hl_update(0, "NvimTreeOpenedFile", { bold = false })

      hl_update(0, "Directory", { bold = true })
      hl_update(0, "NvimTreeFolderName", { link = "Directory" })
      hl_update(0, "NvimTreeRootFolder", { bold = true })

      -- Just like regular buffers:
      hl_update(0, "NvimTreeNormal", { link = "Normal" })
      hl_update(0, "NvimTreeNormalNC", { link = "NormalNC" })
      hl_update(0, "NvimTreeEndOfBuffer", { link = "EndOfBuffer" })

      -- vim.wo.fillchars = 'eob: '
    end,
    keys = {
      { mode = "n", "<leader>e", vim.cmd.NvimTreeFindFileToggle, desc = "Toggle file tree" },
    },
  },

  { -- mini.files
    "echasnovski/mini.files",
    enabled = true,
    event = "BufEnter */",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      mappings = {
        go_in = 'l',
        go_in_plus = '<CR>',
        go_out = 'h',
        go_out_plus = '<BS>',
        reveal_cwd = '@',
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

      -- use :w to save filesystem change
      -- https://github.com/echasnovski/mini.nvim/issues/391
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(ev)
          local buf_id = ev.data.buf_id
          vim.schedule(function()
            vim.api.nvim_buf_set_option(0, 'buftype', 'acwrite')
            vim.api.nvim_buf_set_name(0, tostring(vim.api.nvim_get_current_win()))
            vim.api.nvim_create_autocmd('BufWriteCmd', {
              buffer = buf_id,
              callback = MiniFiles.synchronize,
            })

            -- close with <esc>
            vim.keymap.set("n", "<Esc>", MiniFiles.close, { buffer = buf_id })
            -- Move around without traversing the tree
            vim.keymap.set("n", "<C-h>", "h", { buffer = buf_id })
            vim.keymap.set("n", "<C-j>", "j", { buffer = buf_id })
            vim.keymap.set("n", "<C-k>", "k", { buffer = buf_id })
            vim.keymap.set("n", "<C-l>", "l", { buffer = buf_id })
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

}
