return {
   { -- ufo
      "kevinhwang91/nvim-ufo",
      enabled = false,
      event = "LazyFile",
      dependencies = {
         "kevinhwang91/promise-async"
      },
      init = function()
         vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
         vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
      end,
      -- opts = {
      --    provider_selector = function(bufnr, filetype, buftype)
      --       return { 'treesitter', 'indent'}
      --    end
      -- },
   },
}
