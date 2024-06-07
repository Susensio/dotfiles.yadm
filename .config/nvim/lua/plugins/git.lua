local function format_dotfiles_paths()
   local os = require("utils.os")
   local include = vim.fn.expand("$XDG_CONFIG_HOME") .. "/yadm/include"
   local lines = os.read_lines(include)
   lines = vim.tbl_map(os.expand_vars, lines)
   -- fix glob to vim pattern
   lines = vim.tbl_map(function(line)
      return line:gsub("%*%*", "*")
   end, lines)
   return table.concat(lines, ",")
end

return {
   { -- mini.diff
      "echasnovski/mini.diff",
      event = "LazyFile",
      init = function()
         vim.keymap.set(
            "n",
            "<leader>ug",
            function() require("mini.diff").toggle_overlay(0) end,
            { desc = "Toggle git overlay" }
         )
      end,
      opts = {
         view = {
            style = "sign",
            signs = {
               add = '▎',
               change = '▎',
               delete = '▁',
            },
         },
      },
   },

   { -- baredot
      "ejrichards/baredot.nvim",
      event = "BufRead " .. format_dotfiles_paths(),
      opts = {
         git_dir = "$XDG_DATA_HOME/yadm/repo.git",
         git_work_tree = "$HOME",
      }
   },
}
