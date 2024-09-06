return {
   { -- mini.completion
      "echasnovski/mini.completion",
      enabled = true,
      dependencies = {
         "neovim/nvim-lspconfig",
      },
      event = "LazyFile",
      init = function(plugin)
         require("utils.lsp").on_attach(
            function(client, buffer)
               vim.bo[buffer].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
            end
         )
      end,
      opts = {
         delay = {
            completion = 10^7,
            info = 50,
            signature = 10^7,
         },
         lsp_completion = {
            source_func = "omnifunc",
            auto_setup = false,
         },
         mappings = {
            force_twostep = "<C-Space>",
            force_fallback = "",
         },
         set_vim_settings = false,
      },
   }
}
