return {
  -- { -- lsp-progress
  --   "linrongbin16/lsp-progress.nvim",
  --   main = "lsp-progress",
  --   opts = {
  --     format = function(messages)
  --       if #messages == 0 then
  --         return ""
  --       end
  --     local spinner = messages[1]
  --     return spinner .. " LSP"
  --     end,
  --     client_format = function(client_name, spinner, series_messages)
  --       if #series_messages > 0 then
  --         return spinner
  --       end
  --     end,
  --   },
  --   config = function(plugin, opts)
  --     require("lsp-progress").setup(opts)
  --     vim.api.nvim_create_autocmd("User", {
  --       group = vim.api.nvim_create_augroup("lualine_augroup", { clear = true }),
  --       pattern = "LspProgressStatusUpdated",
  --       callback = require("lualine").refresh,
  --     })
  --   end,
  -- },

  { -- lualine
    "nvim-lualine/lualine.nvim",
    main = "lualine",
    event = "VeryLazy",
    enabled = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "WhoIsSethDaniel/lualine-lsp-progress.nvim",
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
          globalstatus = true,
          refresh = {
            statusline = 500,
          },
        },
        sections = {
          lualine_a = { { "mode", color = { gui = "bold" } } },
          lualine_b = {
            "branch",
            "diff",
            {
              "diagnostics",
              -- symbols = {error = "E", warn = "W", info = "I", hint = "H"},
              cond = function() return not vim.diagnostic.is_disabled(0) end,
            }
          },
          lualine_c = {
            -- {
            --   "filetype",
            --   icon_only = true,
            --   padding = { left = 1, right = 0 },
            -- },
            {
              "filename",
              newfile_status = true,
              path = 1,
              symbols = { newfile = "[N]" },
            },
          },
          lualine_x = {
            {
              "lsp_progress",
              hide = { "copilot" },
              display_components = {
                "spinner"
              },
              separators = {
                spinner = {
                  post = " LSP",
                },
              },
              timer = {
                spinner = 500,
                lsp_client_name_enddelay = 500,
              },
              spinner_symbols = require("copilot-lualine.spinners").dots_negative
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
          lualine_z = {
            {
              "progress",
              color = { gui = "" },
            },
            { "location" }
          },
          -- lualine_z = { { "location" , color = { gui = "bold" } } },
        },
        inactive_sections = {
          -- lualine_a = { { "mode" , color = { gui = "bold" } } },
          -- lualine_b = {"branch", "diff", "diagnostics"},
          lualine_c = {
            -- {
            --   "filetype",
            --   icon_only = true,
            --   padding = { left = 1, right = 0 },
            -- },
            {
              "filename",
              newfile_status = true,
              path = 1,
              symbols = { newfile = "[N]" },
            }
          },
          lualine_x = { "filetype" },
          -- lualine_y = {"progress"},
          -- lualine_z = {"location"},
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
          -- "nvim-tree",
          "lazy",
          "mason",
          "man",
          "quickfix",
          "oil",
          {
            filetypes = { "minipick" },
            sections = {
              lualine_a = { function() return "PICK" end },
              lualine_b = { function()
                return MiniPick.get_picker_opts().source.name
              end },
              lualine_c = { function()
                return "items: " .. #MiniPick.get_picker_matches().all
              end },
            },
          },
          {
            filetypes = { "minifiles" },
            sections = {
              lualine_a = { function() return "FILES" end },
              -- lualine_b = { function()
              --   local ok, minifiles = pcall(require, 'mini.files')
              --   if ok then
              --     return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
              --   else
              --     return ''
              --   end
              -- end },
            },
          },
          {
            filetypes = { "oil" },
            sections = {
              lualine_a = { function() return "OIL" end },
              lualine_b = { function()
                local ok, oil = pcall(require, 'oil')
                if ok then
                  return vim.fn.fnamemodify(oil.get_current_dir(), ":~")
                else
                  return ''
                end
              end },
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
            a = { bg = palette.green, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          insert = {
            a = { bg = palette.blue, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          visual = {
            a = { bg = palette.red, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          replace = {
            a = { bg = palette.orange, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          command = {
            a = { bg = palette.yellow, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          terminal = {
            a = { bg = palette.purple, fg = palette.bg0, gui = "bold" },
            b = { bg = palette.bg3, fg = palette.fg },
            c = { bg = palette.bg1, fg = palette.grey2 },
          },
          inactive = {
            a = { bg = palette.bg1, fg = palette.grey1 },
            b = { bg = palette.bg1, fg = palette.grey1 },
            c = { bg = palette.bg1, fg = palette.grey1 },
          },
        }
      end
      opts.options.theme = theme

      require(plugin.main).setup(opts)
    end
  },


  { -- incline
    "b0o/incline.nvim",
    version = false,
    event = "VeryLazy",
    opts = {
      hide = {
        focused_win = true,
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
