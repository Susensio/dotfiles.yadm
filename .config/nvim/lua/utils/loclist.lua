local M = {}

function M.follow_cursor()
   local curr_win = vim.api.nvim_get_current_win()
   local curr_cursor = vim.api.nvim_win_get_cursor(curr_win)
   local lnum, col = unpack(curr_cursor)
   col = col + 1
   local loclist = vim.fn.getloclist(curr_win)
   -- try to follow cursor
   local line_loclist = {}
   for i, item in ipairs(loclist) do
      if item.lnum == lnum then
         if item.col <= col and item.end_col >= col then
            vim.fn.setloclist(curr_win, {}, 'a', { idx = i })
            return
         end
         table.insert(line_loclist, { i = i, item = item })
      end
      -- they are sorted by lnum, i assume
      if item.lnum > lnum then break end -- early exit
   end
   -- fallback to same line
   if #line_loclist > 0 then
      vim.fn.setloclist(curr_win, {}, 'a', { idx = line_loclist[1].i })
   end
end

function M.is_visible()
   local curr_win = vim.api.nvim_get_current_win()
   local loclist_id = vim.fn.getloclist(curr_win, { winid = 0 }).winid
   return loclist_id ~= 0
end

return M
