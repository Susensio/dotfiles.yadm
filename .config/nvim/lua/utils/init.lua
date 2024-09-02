local M = {}

function M.highlight_update(ns, name, opts)
   local ns_id
   if ns == 0 then
      ns_id = ns
   else
      ns_id = vim.api.nvim_get_namespaces()[ns]
   end
   local hl = vim.api.nvim_get_hl(ns_id, { name = name })
   -- default must be false, or the hl won't update
   hl = vim.tbl_extend("force", hl, opts, {default = false})
   vim.api.nvim_set_hl(ns_id, name, hl)
end

function M.is_visual_selection_empty()
   -- works even without exiting visual mode
   if vim.fn.mode() == 'V' then
      -- VISUAL-LINE
      return false
   elseif vim.fn.mode() == 'v' then
      -- VISUAL (char)
      local start_pos = vim.fn.getpos('.')
      local end_pos = vim.fn.getpos('v')
      return vim.deep_equal(start_pos, end_pos)
   else
      return false
   end
end

function M.close_floating_windows()
   local inactive_floating_wins = vim.fn.filter(vim.api.nvim_list_wins(), function(_, win)
      return vim.api.nvim_win_get_config(win).relative == "win"
         and win ~= vim.api.nvim_get_current_win()
   end)
   for _, win in ipairs(inactive_floating_wins) do
      vim.api.nvim_win_close(win, false)
   end
   if #inactive_floating_wins > 0 then
      return true
   end
end

function M.color_blend(color1, color2, percentage)
   -- Convert hex color to RGB components
   local function hexToRGB(hex)
      hex = hex:gsub("#","")
      return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
   end

   -- Interpolate between two values
   local function interpolate(a, b, percentage)
      return a + (b - a) * percentage
   end

   local r1, g1, b1 = hexToRGB(color1)
   local r2, g2, b2 = hexToRGB(color2)

   -- Blend the colors
   local r = interpolate(r1, r2, percentage)
   local g = interpolate(g1, g2, percentage)
   local b = interpolate(b1, b2, percentage)

   -- Convert back to hex and return
   return string.format("#%02x%02x%02x", r, g, b)
end

function M.has(plugin)
   return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

function M.refresh_statusline()
   local ok, plugin = pcall(require, "lualine")
   if ok then
      plugin.refresh()
   end
end

function M.timeit(cb)
   local init_time = os.clock()
   local result
   for _ = 1, 1000 do
      result = cb()
   end
   local end_time = os.clock()
   vim.notify("Time: " .. (end_time - init_time)/1000 .. "s")
   return result
end

return M
