return {
  { -- mini.surround
    "echasnovski/mini.surround",
    enabled = true,
    event = "VeryLazy",
    config = true,
    opts = function()
      local ts_input = require('mini.surround').gen_spec.input.treesitter
      vim.keymap.set('n', 'yss', 'ys_', { remap = true })
      return {
        mappings = {
          add = 'gs',
          delete = 'ds',
          replace = 'cs',
          -- disabled
          highlight = '',
          find = '',
          find_left = '',
          update_n_lines = '',

          -- Add this only if you don't want to use extended mappings
          suffix_last = '',
          suffix_next = '',
        },
        custom_surroundings = {
          f = { input = ts_input({ outer = "@call.outer", inner = "@call.inner" }) },
        },
        search_method = 'cover_or_next',
        silent = true,
      }
    end,
  },
}
