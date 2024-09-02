return {
   {
      "chrishrb/gx.nvim",
      keys = {
         { "gx", "<cmd>Browse<cr>", mode = { "n", "x" }, desc = "Open URL under cursor" },
      },
      cmd = { "Browse" },
      init = function ()
         vim.g.netrw_nogx = 1
      end,
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {
         handlers = {
            plugin = true,
            github = true,
            search = true,
         }
      },
      submodules = false, -- not needed, submodules are required only for tests
   },
}
