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
         "echasnovski/mini.icons",
         "linrongbin16/lsp-progress.nvim",
         {
            "Susensio/copilot-lualine",
            branch = "bugfix/is-sleep-logic"
         },
      },
      init = function()
         vim.o.winbar = " "
         vim.g.lualine_laststatus = vim.o.laststatus
         if vim.fn.argc(-1) > 0 then
            -- set an empty statusline till lualine loads
            vim.o.statusline = " "
         else
            -- hide the statusline on the starter page
            vim.o.laststatus = 0
         end
         vim.opt.showmode = false

         vim.o.showtabline = 1
      end,
      opts = function()
         local colors = _G.palette
         local palette = colors.raw

         local mini_filetype = require("lualine.components.filetype"):extend()
         function mini_filetype:apply_icon()
            local icon, icon_highlight_group = MiniIcons.get("file", vim.fn.expand("%:t"))
            if icon == nil then
               icon, icon_highlight_group = MiniIcons.get("filetype", vim.bo.filetype)
            end
            icon_highlight_group = icon_highlight_group .. 'Inv'
            if self.options.colored then
               -- icon = require("utils").highlight(icon_highlight_group)(icon)
               local highlight_color = require("lualine.utils.utils").extract_highlight_colors(icon_highlight_group, 'fg')
               if highlight_color then
                  local default_highlight = self:get_default_hl()
                  local icon_highlight = self.icon_hl_cache[highlight_color]
                  if not icon_highlight or not require("lualine.highlight").highlight_exists(icon_highlight.name .. '_normal') then
                     icon_highlight = self:create_hl({ fg = highlight_color }, icon_highlight_group)
                     self.icon_hl_cache[highlight_color] = icon_highlight
                  end

                  icon = self:format_hl(icon_highlight) .. icon .. default_highlight
               end
            end
            icon = icon .. " "
            if self.options.icon_only then
               self.status = icon
            else
               self.status = icon .. self.status
            end
         end

         return {
            options = {
               icons_enabled = true,
               -- theme = "auto",
               section_separators = { left = "", right = "" },
               component_separators = { left = "", right = "" },
               -- component_separators = { left = "◢", right = "◣ " },
               disabled_filetypes = {
                  "starter",
                  winbar = {
                     "qf",
                  }
               },
               ignore_focus = {
                  -- "minifiles",
                  -- "minipick",
               },
               globalstatus = true,
               always_show_tabline = false,
               refresh = {
                  statusline = 500,
               },
            },
            sections = {
               lualine_a = {
                  {
                     "mode",
                  },
                  -- {
                  --    "filetype",
                  --    colored = true,
                  --    icon_only = true,
                  --    padding = { left = 1, right = 0 },
                  -- },
                  -- {
                  --    "filename",
                  --    newfile_status = true,
                  --    path = 1,
                  --    symbols = { newfile = "[N]" },
                  --    separator = { right = "◤", },
                  --    padding = { left = 0, right = 1 },
                  -- },
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
               },
               lualine_c = {
                  {
                     "diagnostics",
                     symbols = require("utils.symbols").spaced.diagnostics,
                     cond = function() return vim.diagnostic.is_enabled({ bufnr=0 }) end,
                  },
                  {
                     "grapple",
                  },
               },
               lualine_x = {
                  {
                     function()
                        return require('lsp-progress').progress()
                     end,
                  },
                  -- {
                  --    "searchcount",
                  -- },
                  {
                     require("lazy.status").updates,
                     cond = require("lazy.status").has_updates,
                     color = { fg = (function()
                        local default = "#ff9e64"
                        local success, cs_orange = pcall(function() return colors.orange end)
                        return success and cs_orange or default
                     end)() },     -- palette set from colorscheme
                  },
                  {
                     "copilot",
                     show_colors = true,
                     symbols = {
                        status = {
                           hl = {
                              enabled = colors.green,
                              sleep = colors.darkwhite,
                              disabled = colors.lightgrey,
                              warning = colors.orange,
                              unknown = colors.red,
                           },
                        },
                        spinner_color = colors.green,
                        -- spinners = {" "},
                        spinners = {" "},
                     },
                  },
               },
               lualine_y = {
                  {
                     "encoding",
                     -- cond = function()
                     --    return vim.bo.fileencoding ~= "utf-8"
                     -- end,
                  },
                  {
                     "fileformat",
                     cond = function()
                        return vim.bo.fileformat ~= "unix"
                     end,
                     padding = { left = 0, right = 2 },
                  },
               },
               lualine_z = {
                  {
                     "progress",
                  },
                  { -- total number of lines
                     function()
                        return "/" .. vim.fn.line("$")
                     end,
                     padding = { left = 0, right = 1 },
                  },
                  -- { "mode" },
               },
            },
            -- inactive_sections = {
            --    lualine_a = {
            --       {
            --          "filetype",
            --          colored = false,
            --          icon_only = true,
            --          padding = { left = 1, right = 0 },
            --       },
            --       {
            --          "filename",
            --          newfile_status = true,
            --          path = 1,
            --          symbols = { newfile = "[N]" },
            --          separator = { right = "◤", },
            --          padding = { left = 0, right = 1 },
            --       },
            --    },
            --    lualine_b = {},
            --    lualine_c = {},
            --    lualine_x = {},
            --    lualine_y = {},
            --    lualine_z = {},
            -- },
            winbar = {
               lualine_a = {
                  {
                     mini_filetype,
                     colored = true,
                     icon_only = true,
                     padding = { left = 1, right = 0 },
                     color = function()
                        return { bg = palette.fg, fg = palette.bg0, gui = "bold" }
                     end,
                  },
                  {
                     "filename",
                     newfile_status = true,
                     path = 1,
                     symbols = { newfile = "[N]" },
                     separator = { right = "◣", },
                     -- padding = { left = 0, right = 1 },
                     color = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
                  },
               },
            },
            inactive_winbar = {
               lualine_a = {
                  {
                     mini_filetype,
                     colored = false,
                     icon_only = true,
                     padding = { left = 1, right = 0 },
                  },
                  {
                     "filename",
                     newfile_status = true,
                     path = 1,
                     symbols = { newfile = "[N]" },
                     separator = { right = "◣", },
                  },
               },
            },
            tabline = {
               lualine_a = {
                  {
                     "tabs",
                     mode = 0,
                     show_modified_status = false,
                     padding = 1,
                     -- component_separators = { left = " ", right = " " },
                     -- separator = { left = "◢", right = "◣" },
                  },
               },
            },
            extensions = {
               "lazy",
               "mason",
               "man",
               "quickfix",
               -- "neo-tree",
               {
                  filetypes = { "neo-tree" },
                  sections = {
                     lualine_a = {
                        {
                           function() return "TREE" end,
                           separator = { right = "◤", },
                        }
                     },
                  },
               },

               {
                  filetypes = { "Outline" },
                  sections = {
                     lualine_a = {
                        {
                           function() return "OUTLINE" end,
                           separator = { right = "◤", },
                        }
                     },
                  },
               },
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
               -- {
               --    filetypes = { "oil" },
               --    sections = {
               --       -- lualine_b = { 'branch' },
               --       -- lualine_b = {
               --       --   -- {
               --       --   --   -- 'branch',
               --       --   --   function()
               --       --   --     -- local cache = {}
               --       --   --
               --       --   --     local ok, oil = pcall(require, 'oil')
               --       --   --     if ok then
               --       --   --       local current_dir = oil.get_current_dir()
               --       --   --       local gb_module = require('lualine.components.branch.git_branch')
               --       --   --       local git_dir = gb_module.find_git_dir(current_dir)
               --       --   --       return "todo..."
               --       --   --     else
               --       --   --       return ''
               --       --   --     end
               --       --   --   end,
               --       --   --   icon = ''
               --       --   -- },
               --       -- },
               --       lualine_a = {
               --          {
               --             function()
               --                local ok, oil = pcall(require, 'oil')
               --                if ok then
               --                   return vim.fn.fnamemodify(oil.get_current_dir() or '', ":~")
               --                else
               --                   return ''
               --                end
               --             end,
               --             separator = { right = "◤", },
               --          }
               --       },
               --       lualine_z = { 'mode' },
               --    },
               -- },
            },
         }
      end,
      config = function(plugin, opts)
         vim.o.laststatus = vim.g.lualine_laststatus
         vim.o.winbar = ""

         ---@type string|table
         local theme = "auto"
         -- theme = "everforest"
         local colors = _G.palette
         local palette = colors.raw
         theme = {
            normal = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.green, fg = palette.bg0, gui = "bold" },
               b = { bg = palette.bg3, fg = palette.fg },
               c = { bg = nil, fg = palette.grey2 },
               z = { bg = palette.green, fg = palette.bg0, gui = "bold" },
            },
            insert = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.blue, fg = palette.bg0, gui = "bold" },
               b = { bg = palette.bg3, fg = palette.fg },
               c = { bg = nil, fg = palette.grey2 },
               z = { bg = palette.blue, fg = palette.bg0, gui = "bold" },
            },
            visual = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.red, fg = palette.bg0, gui = "bold" },
               b = { bg = palette.bg3, fg = palette.fg },
               c = { bg = nil, fg = palette.grey2 },
               z = { bg = palette.red, fg = palette.bg0, gui = "bold" },
            },
            replace = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.orange, fg = palette.bg0, gui = "bold" },
               b = { bg = palette.bg3, fg = palette.fg },
               c = { bg = nil, fg = palette.grey2 },
               z = { bg = palette.orange, fg = palette.bg0, gui = "bold" },
            },
            command = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.yellow, fg = palette.bg0, gui = "bold" },
               b = { bg = palette.bg3, fg = palette.fg },
               c = { bg = nil, fg = palette.grey2 },
               z = { bg = palette.yellow, fg = palette.bg0, gui = "bold" },
            },
            terminal = {
               -- a = { bg = palette.fg, fg = palette.bg0, gui = "bold" },
               a = { bg = palette.purple, fg = palette.bg0, gui = "bold" },
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
         opts.options.theme = theme

         -- local showtabline = vim.o.showtabline
         require(plugin.main).setup(opts)
         -- vim.o.showtabline = showtabline
      end
   },

   -- { -- incline
   --    "b0o/incline.nvim",
   --    main = "incline",
   --    enabled = false,
   --    version = false,
   --    event = "VeryLazy",
   --    opts = {
   --       render = function(props)
   --          local colors = _G.palette
   --          local palette = colors.raw
   --
   --          local bufname = vim.api.nvim_buf_get_name(props.buf)
   --          local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(bufname)
   --
   --
   --          local res = bufname ~= "" and vim.fn.fnamemodify(bufname, ":~:.") or "[No Name]"
   --
   --          if vim.bo[props.buf].modified then
   --             res = res .. " [+]"
   --          end
   --
   --          if bufname ~= "" and vim.bo[props.buf].buftype == ""  and vim.fn.filereadable(bufname) == 0 then
   --             res = res .. " [New]"
   --          end
   --
   --          if vim.bo[props.buf].readonly or vim.bo[props.buf].modifiable == false then
   --             res = res .. " [-]"
   --          end
   --
   --          local bg = props.focused and palette.fg or palette.grey0
   --          local fg = palette.bg0
   --
   --          return {
   --             ft_icon and { " "..ft_icon, guifg = ft_color, guibg = bg } or "",
   --             { " "..res.." ", gui = "bold", guibg = bg, guifg = fg },
   --             { "◤", guifg = bg, gui = "NONE" },
   --          }
   --       end,
   --       hide = {
   --          focused_win = false,
   --          -- only_win = "count_ignored",
   --       },
   --       highlight = {
   --          groups = {
   --             InclineNormal = "Normal",
   --             InclineNormalNC = "NormalNC",
   --          },
   --       },
   --       window = {
   --          overlap = {
   --             borders = true,
   --          },
   --          margin = {
   --             horizontal = 0,
   --             vertical = 1,
   --          },
   --          padding = 0,
   --          placement = {
   --             horizontal = "left",
   --             vertical = "bottom",
   --          }
   --       },
   --    },
   -- }
}
