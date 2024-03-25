-- try to move bewteen lazy plugin specs
if vim.fn.expand('%:p'):find(vim.fn.stdpath("config").."/lua/plugins/") then
  local function prev_plugin_start() vim.fn.search("^  {", "bsW") end
  local function next_plugin_start() vim.fn.search("^  {", "sW") end
  local function prev_plugin_end() vim.fn.search("^  }", "bsW") end
  local function next_plugin_end() vim.fn.search("^  }", "sW") end

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

  -- -- not working in visual mode..
  -- vim.keymap.set(
  --   { "o", "x" },
  --   "ap",
  --   ":<C-u>call " .. prev_plugin_start .. "<CR>" .. ":normal! 0V<CR>" .. ":call " .. next_plugin_end .. "<CR>",
  --   { desc = "Plugin next end", buffer = true }
  -- )
  -- vim.keymap.set(
  --   { "o", "x" },
  --   "ip",
  --   ":<C-u>call " .. prev_plugin_start .. "<CR>" .. ":normal! 0jV<CR>" .. ":call " .. next_plugin_end .. "<CR>k",
  --   { desc = "Plugin next end", buffer = true }
  -- )
end
