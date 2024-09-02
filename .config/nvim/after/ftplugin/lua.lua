-- try to move bewteen lazy plugin specs
if vim.fn.expand('%:p'):find(vim.fn.stdpath("config").."/lua/plugins/") then
   local function prev_plugin_start() vim.fn.search("^  {", "bW") end
   local function next_plugin_start() vim.fn.search("^  {", "W") end
   local function prev_plugin_end() vim.fn.search("^  }", "bW") end
   local function next_plugin_end() vim.fn.search("^  }", "W") end

   vim.keymap.set(
      { "n", "x" },
      "[[",
      prev_plugin_start,
      { desc = "Plugin previous", buffer = true }
   )
   vim.keymap.set(
      { "n", "x" },
      "]]",
      next_plugin_start,
      { desc = "Plugin next", buffer = true }
   )
   vim.keymap.set(
      { "n", "x" },
      "[]",
      prev_plugin_end,
      { desc = "Plugin previous end", buffer = true }
   )
   vim.keymap.set(
      { "n", "x" },
      "][",
      next_plugin_end,
      { desc = "Plugin next end", buffer = true }
   )

   -- text objects
   vim.keymap.set(
      { "o", "x" },
      "ap",
      function()
         vim.cmd("normal! \28\14")
         vim.cmd("normal! $")
         prev_plugin_start()
         vim.cmd("normal! 0V")
         next_plugin_end()
         -- keep selecting as long as next line is empty
         while vim.fn.getline(vim.fn.line('.')+1) == "" do
            vim.api.nvim_win_set_cursor(0, {vim.fn.line('.')+1, 0})
         end
      end,
      { desc = "Plugin next end", buffer = true }
   )
   vim.keymap.set(
      { "o", "x" },
      "ip",
      function()
         vim.cmd('normal! \28\14')
         vim.cmd("normal! $")
         prev_plugin_start()
         vim.cmd("normal! 0V")
         next_plugin_end()
      end,
      { desc = "Plugin next end", buffer = true }
   )
end
