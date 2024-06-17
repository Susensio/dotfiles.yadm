return {
   {
      "emmanueltouzery/decisive.nvim",
      ft = {'csv'},
      cmd = "Align",
      init = function()
         vim.api.nvim_create_user_command(
            "Align",
            function()
               if vim.b.aligned then
                  require('decisive').align_csv_clear({})
               else
                  require('decisive').align_csv({})
               end
            end,
            {}
         )
      end,
   },
}
