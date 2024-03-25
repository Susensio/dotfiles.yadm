-- MONOKAI PRO
-- name = "monokai_pro",
-- aqua = "#78DCE8",
-- base0 = "#222426",
-- base1 = "#211F22",
-- base2 = "#26292C",
-- base3 = "#2E323C",
-- base4 = "#333842",
-- base5 = "#4d5154",
-- base6 = "#72696A",
-- base7 = "#B1B1B1",
-- base8 = "#e3e3e1",
-- black = "#000000",
-- border = "#A1B5B1",
-- brown = "#504945",
-- diff_add = "#3d5213",
-- diff_change = "#27406b",
-- diff_remove = "#4a0f23",
-- diff_text = "#23324d",
-- green = "#A9DC76",
-- grey = "#72696A",
-- orange = "#FC9867",
-- pink = "#FF6188",
-- purple = "#AB9DF2",
-- red = "#FD6883",
-- white = "#FFF1F3",
-- yellow = "#FFD866"

return {
  { -- monokai
    "tanvirtin/monokai.nvim",
    main = "monokai",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = function(plugin, opts)
      local blend = require("utils").color_blend
      local monokai = require("monokai")
      local palette = monokai.pro

      local background = "none"          -- default base2, tmux grey7, using none to respect unfocused panes
      local background_color = "#121212" -- grey7, used for blending
      local background_float = "grey8"
      local background_nc = "grey13"
      local foreground_nc = "grey70"

      -- export to global namespace
      _G.palette = {
        black = palette.black,
        darkgrey = palette.base3,
        grey = palette.base5,
        lightgrey = palette.base6,
        darkwhite = palette.base7,
        white = palette.white,
        red = palette.red,
        green = palette.green,
        blue = palette.aqua,
        purple = palette.purple,
        yellow = palette.yellow,
        orange = palette.orange,
      }

      opts.palette = monokai.pro
      -- background = palette.base1   -- default base2

      opts.custom_hlgroups = {
        -- background
        Normal = { fg = palette.white, bg = background },
        NormalFloat = { fg = palette.white, bg = background_float },
        CursorLineNr = { fg = palette.orange, bg = background },
        LineNr = { fg = palette.base6, bg = background },
        SignColumn = { fg = palette.white, bg = background },
        Terminal = { fg = palette.white, bg = background },

        -- Inactive
        NormalNC = { fg = foreground_nc, bg = background_nc },

        -- LINES
        -- Cursor
        CursorLine = { bg = palette.base2 },
        -- Folds less intrusive
        Folded = { fg = palette.grey, bg = palette.base1 }, -- default base3

        -- Listchars like eol
        NonText = { fg = palette.base5 },

        -- IndentBlackLine
        IblIndent = { fg = palette.base5 },
        IblScope = { fg = palette.base5 },

        Cursor = { style = 'reverse' },
        iCursor = { fg = palette.white },

        Search = { fg = palette.base1, bg = "#A68D43" },
        CurSearch = { fg = palette.base2, bg = palette.yellow },
        IncSearch = { fg = palette.base2, bg = palette.yellow },

        DiagnosticError = { fg = palette.red },
        DiagnosticWarn = { fg = palette.yellow },
        DiagnosticInfo = { fg = palette.white },
        DiagnosticHint = { fg = palette.aqua },
        DiagnosticVirtualTextError = { fg = blend(palette.red, background_color, 0.2) },
        DiagnosticVirtualTextWarn = { fg = blend(palette.yellow, background_color, 0.4) },
        DiagnosticVirtualTextInfo = { fg = blend(palette.white, background_color, 0.5) },
        DiagnosticVirtualTextHint = { fg = blend(palette.aqua, background_color, 0.5) },

        TreesitterContext = { bg = palette.base1 },                               -- default base3
        TreesitterContextLineNumber = { fg = palette.base5, bg = palette.base1 }, -- default base3
        TreesitterContextBottom = { sp = palette.base5 },

        TSDefinition = { bg = palette.base5 },
        TSDefinitionUsage = { bg = palette.base5 },

        LspReferenceText = { bg = palette.base5 },
        LspReferenceRead = { bg = palette.base5 },
        LspReferenceWrite = { bg = palette.base5 },
      }

      return opts
    end,
    -- config = function(plugin, opts)
    --   require(plugin.main).setup(opts)
    --   vim.opt.guicursor:append("i-ci-ve:Cursor2")
    -- end
  },

  { -- base16
    "RRethy/nvim-base16",
    main = "base16-colorscheme",
    -- dependencies = { "tanvirtin/monokai.nvim" },
    enabled = false,
    lazy = true,
    config = function(plugin, opts)
      -- vim.env.BASE16_THEME = "monokai"
      -- do return end
      local monokai = require("monokai").pro
      local base16 = {
          base00 = monokai.base1,
          base01 = monokai.base3,
          base02 = monokai.base4,
          base03 = monokai.base5,
          base04 = monokai.base6,
          base05 = monokai.base7,
          base06 = monokai.base8,
          base07 = monokai.white,
          base08 = monokai.red,
          base09 = monokai.orange,
          base0A = monokai.yellow,
          base0B = monokai.green,
          base0C = monokai.aqua,
          base0D = monokai.aqua,
          base0E = monokai.purple,
          base0F = monokai.brown,
      }
      require(plugin.main).setup(base16)
    end,
  },

  { -- monokai-pro
    "loctvl842/monokai-pro.nvim",
    main = "monokai-pro",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true,
      filter = "pro",
      override = function()
        return {
          NormalNC = { bg = "grey10" },
        }
      end,
    },
    config = function(plugin, opts)
      require(plugin.main).setup(opts)
      vim.cmd.colorscheme("monokai-pro")
    end,
  },

  { -- kanagawa
    "rebelot/kanagawa.nvim",
    main = "kanagawa",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      dimInactive = true,
      theme = "wave",
    },
    config = function(plugin, opts)
      require(plugin.main).setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },

  { -- sonokai
    "sainnhe/sonokai",
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function(plugin, opts)
      vim.g.sonokai_style = "default"
      vim.g.sonokai_better_performance = 1
      vim.g.sonokai_enable_italics = 1
      vim.g.sonokai_disable_italic_comment = 0
      vim.g.sonokai_transparent_background = 1
      -- vim.g.sonokai_dim_inaceive_windows = 1
      -- vim.g.sonokai_show_eob = 1
      -- vim.cmd.colorscheme("sonokai")
    end,
  },

  { -- everforest-nvim
    "neanias/everforest-nvim",
    main = 'everforest',
    lazy = false,
    enabled = true,
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      background = "hard",
      italic_comments = true,
      transparent_background_level = 1,
      ui_contrast = "high",
      dim_inactive_windows = false, -- done via highlights
      float_style = "dim",
      colours_override = function(palette)
        palette.fg_dim = palette.fg
        palette.fg = "#D8D3BA"
        local bg_dim = palette.bg_dim
        palette.bg_dim = palette.bg0
        palette.bg0 = bg_dim
      end,
      on_highlights = function(hl, palette)
        hl.NormalNC = { fg = palette.fg_dim, bg = palette.bg_dim }
        hl.NormalFloat = { bg = palette.bg }
        hl.TSString = { link = "Yellow" }
        hl.Search = { fg = palette.bg1, bg = palette.yellow }
        hl.CurSearch = { fg = palette.bg0, bg = palette.orange }
        hl.IncSearch = { fg = palette.bg0, bg = palette.orange }
      end,
    },
    config = function(plugin, opts)
      local everforest = require(plugin.main)
      everforest.setup(opts)
      vim.cmd.colorscheme("everforest")

      -- HACK: export to global namespace
      local palette = require("everforest.colours").generate_palette(
        everforest.config,
        vim.o.background
      )
      _G.palette = {
        black = palette.bg_dim,
        darkgrey = palette.bg1,
        grey = palette.bg5,
        lightgrey = palette.grey0,
        darkwhite = palette.bg5,
        white = palette.fg,
        red = palette.red,
        green = palette.green,
        blue = palette.blue,
        aqua = palette.aqua,
        purple = palette.purple,
        yellow = palette.yellow,
        orange = palette.orange,
        raw = palette
      }
    end,
  },

  { -- everforest
    "sainnhe/everforest",
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function(plugin, opts)
      -- vim.g.everforest_background = "hard"
      vim.g.everforest_transparent_background = 1
      vim.g.everforest_ui_contrast = "high"
      vim.g.everforest_float_style = "bright"
      -- vim.g.everforest_dim_inactive_windows = 1
      vim.cmd.colorscheme("everforest")
    end,
  },

  { -- rose-pine
    "rose-pine/neovim",
    name = "rose-pine",
    enabled = false,
    lazy = false,
    version = false,
    priority = 1000,
    opts = {
      variant = "main",
      styles = {
        transparency = true,
      },
    },
    config = function(plugin, opts)
      require(plugin.name).setup(opts)
      vim.cmd.colorscheme("rose-pine")
    end
  },

  { -- catppuccin
    "catppuccin/nvim",
    name = "catppuccin",
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      -- dim_inactive = {
      --   enabled = true,
      --   shade = "bright",
      --   percentage = 0.5,
      -- },
      integrations = {
        mason = true,
        treesitter = true,
        treesitter_context = true,
        mini = {
          enabled = true,
        },
      },
    },
    config = function(plugin, opts)
      require(plugin.name).setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end
  },


  { -- bamboo
    'ribru17/bamboo.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      dim_inactive = true,
      code_style = {
        keywords = "bold",
      },
      highlights = {
        NormalFloat = { bg = "none" }
      },
    },
    config = function(plugin, opts)
      require('bamboo').setup(opts)
      require('bamboo').load()
    end,
  },
}
