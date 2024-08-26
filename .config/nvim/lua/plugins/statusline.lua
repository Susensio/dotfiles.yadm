return {
  { -- lsp-progress
    "linrongbin16/lsp-progress.nvim",
    main = "lsp-progress",
    opts = {
      format = function(messages)
        if #messages == 0 then
          return ""
        end
      local spinner = messages[1]
      return spinner .. " LSP"
      end,
      client_format = function(client_name, spinner, series_messages)
        if #series_messages > 0 then
          return spinner
        end
      end,
    },
    config = function(plugin, opts)
      require("lsp-progress").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("lualine_augroup", { clear = true }),
        pattern = "LspProgressStatusUpdated",
        callback = require("lualine").refresh,
      })
    end,
  },

  { -- lualine
    "nvim-lualine/lualine.nvim",
    main = "lualine",
    event = "VeryLazy",
    enabled = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "linrongbin16/lsp-progress.nvim",
      { "AndreM222/copilot-lualine", dev = false },
    },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
      vim.opt.showmode = false

    end,
    opts = function()

      return {
        options = {
          icons_enabled = true,
          -- theme = "auto",
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
          disabled_filetypes = { "starter" },
          ignore_focus = {
            -- "minifiles",
            -- "minipick",
          },
          globalstatus = false,
          refresh = {
            statusline = 500,
          },
        },
        sections = {
          -- lualine_c = { { "mode", color = { gui = "bold" } } },
          lualine_a = {
            {
              "filename",
              newfile_status = true,
              path = 1,
              symbols = { newfile = "[N]" },
              separator = { right = "◤", },
              -- padding = { left = 0, right = 1 },
            },
          },
          lualine_b = {
            "branch",
            {
              "diff",
              source = function()
                local summary = vim.b.minidiff_summary
                return summary
                  and {
                    added = summary.add,
                    modified = summary.change,
                    removed = summary.delete,
                  }
              end,
              padding = { left = 0, right = 1 },
            },
            {
              "diagnostics",
              -- symbols = {error = "E", warn = "W", info = "I", hint = "H"},
              cond = function() return vim.diagnostic.is_enabled({ bufnr=0 }) end,
            }
          },
          lualine_c = {},
          lualine_x = {
            {
              function()
                return require('lsp-progress').progress()
              end,
            },
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = { fg = (function()
                local default = "#ff9e64"
                local success, cs_orange = pcall(function() return _G.palette.orange end)
                return success and cs_orange or default
              end)() },     -- palette set from colorscheme
            },
            {
              "copilot",
              show_colors = true,
              symbols = {
                status = {
                  hl = {
                    enabled = _G.palette.green,
                    sleep = _G.palette.darkwhite,
                    disabled = _G.palette.lightgrey,
                    warning = _G.palette.orange,
                    unknown = _G.palette.red,
                  },
                },
                spinner_color = _G.palette.green,
                -- spinners = {" "},
                spinners = {" "},
              },
            },
          },
          lualine_y = { "filetype" },
          lualine_z = { "mode" },
        },
        inactive_sections = {
          lualine_a = {
            {
              "filename",
              newfile_status = true,
              path = 1,
              symbols = { newfile = "[N]" },
              separator = { right = "◤", },
            },
          },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        -- winbar = {
        --   lualine_z = {
        --     {
        --       "filename"
        --     },
        --   },
        -- },
        -- inactive_winbar = {
        --   lualine_y = {
        --     {
        --       "filename"
        --     },
        --   },
        -- },
        extensions = {
          "lazy",
          "mason",
          "man",
          "quickfix",
          -- {
          --   filetypes = { "minipick" },
          --   sections = {
          --     lualine_a = { function() return "PICK" end },
          --     lualine_b = { function()
          --       return MiniPick.get_picker_opts().source.name
          --     end },
          --     lualine_c = { function()
          --       return "items: " .. #MiniPick.get_picker_matches().all
          --     end },
          --   },
          -- },
          -- {
          --   filetypes = { "minifiles" },
          --   sections = {
          --     lualine_a = { function() return "FILES" end },
          --     -- lualine_b = { function()
          --     --   local ok, minifiles = pcall(require, 'mini.files')
          --     --   if ok then
          --     --     return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
          --     --   else
          --     --     return ''
          --     --   end
          --     -- end },
          --   },
          -- },
          -- "oil",
          {
            filetypes = { "oil" },
            sections = {
              -- lualine_b = { 'branch' },
              -- lualine_b = {
              --   -- {
              --   --   -- 'branch',
              --   --   function()
              --   --     -- local cache = {}
              --   --
              --   --     local ok, oil = pcall(require, 'oil')
              --   --     if ok then
              --   --       local current_dir = oil.get_current_dir()
              --   --       local gb_module = require('lualine.components.branch.git_branch')
              --   --       local git_dir = gb_module.find_git_dir(current_dir)
              --   --       return "todo..."
              --   --     else
              --   --       return ''
              --   --     end
              --   --   end,
              --   --   icon = ''
              --   -- },
              -- },
              lualine_a = {
                {
                  function()
                    local ok, oil = pcall(require, 'oil')
                    if ok then
                      return vim.fn.fnamemodify(oil.get_current_dir() or '', ":~")
                    else
                      return ''
                    end
                  end,
                  separator = { right = "◤", },
                }
              },
              lualine_z = { 'mode' },
            },
          },
        },
      }
    end,
    config = function(plugin, opts)
      vim.o.laststatus = vim.g.lualine_laststatus

      ---@type string|table
      local theme = "auto"
      if vim.g.colors_name == "monokai_pro" then
        local colors = _G.palette
        theme = {
          normal = {
            a = { bg = colors.blue, fg = colors.darkgrey, gui = "bold" },
            b = { bg = colors.grey, fg = colors.blue },
            c = { bg = colors.darkgrey, fg = colors.white},
          },
          insert = {
            a = { bg = colors.green, fg = colors.darkgrey, gui = "bold" },
            b = { bg = colors.grey, fg = colors.green },
            c = { bg = colors.darkgrey, fg = colors.white},
          },
          replace = {
            a = { bg = colors.red, fg = colors.darkgrey, gui = "bold" },
            b = { bg = colors.grey, fg = colors.red },
            c = { bg = colors.darkgrey, fg = colors.white},
          },
          visual = {
            a = { bg = colors.purple, fg = colors.darkgrey, gui = "bold" },
            b = { bg = colors.grey, fg = colors.purple },
            c = { bg = colors.darkgrey, fg = colors.white},
          },
          command = {
            a = { bg = colors.yellow, fg = colors.darkgrey, gui = "bold" },
            b = { bg = colors.grey, fg = colors.yellow },
            c = { bg = colors.darkgrey, fg = colors.white},
          },
          inactive = {
            a = { bg = colors.darkgrey, fg = colors.lightgrey, gui = "bold" },
            b = { bg = colors.darkgrey, fg = colors.lightgrey },
            c = { bg = colors.darkgrey, fg = colors.lightgrey },
          },
        }
      elseif vim.g.colors_name == "everforest" then
        theme = "everforest"
        local colors = _G.palette
        local palette = colors.raw
        theme = {
          normal = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.green, fg = palette.bg0, gui = "bold" },
          },
          insert = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.blue, fg = palette.bg0, gui = "bold" },
          },
          visual = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.red, fg = palette.bg0, gui = "bold" },
          },
          replace = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.orange, fg = palette.bg0, gui = "bold" },
          },
          command = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.yellow, fg = palette.bg0, gui = "bold" },
          },
          terminal = {
            a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = nil, fg = palette.grey2 },
            z = { bg = palette.purple, fg = palette.bg0, gui = "bold" },
          },
          inactive = {
            a = { bg = palette.grey0, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.grey1 },
            c = { bg = palette.bg_dim, fg = palette.grey1 },
            z = { bg = palette.grey0, fg = palette.bg1, gui = "bold" },
          },
        }
      end
      opts.options.theme = theme

      require(plugin.main).setup(opts)
    end
  },


  { -- incline
    "b0o/incline.nvim",
    enabled = false,
    version = false,
    event = "VeryLazy",
    opts = {
      hide = {
        focused_win = false,
        only_win = "count_ignored",
      },
      window = {
        overlap = {
          borders = true,
        },
      },
    },
  }
}
