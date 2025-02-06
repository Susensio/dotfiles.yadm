return {
   {
      "neovim/nvim-lspconfig",
      optional = true,
      opts = {
         servers = {
            lua_ls = {
               on_init = function(client)
                  -- Fix comment tags conflict
                  vim.api.nvim_set_hl(0, '@lsp.type.comment.lua', {})
               end,
               settings = {
                  Lua = {
                     hint = {
                        enable = true,
                        arrayIndex = false,
                     },
                  },
               },
            }
         }
      },
   },

   { -- lazydev
      "folke/lazydev.nvim",
      ft = "lua",
      config = true,
   },
}
