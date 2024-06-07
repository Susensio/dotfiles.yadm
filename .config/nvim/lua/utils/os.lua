local M = {}

function M.expand_vars(str)
   -- it can have underscore
   local result, _ = str:gsub('$([%w_]+)', os.getenv)
   return result
end

function M.read_lines(path)
   local file = io.open(path, 'r')
   if not file then
      return {}
   end
   local content = file:read('*a')
   file:close()
   local lines = {}
   for line in content:gmatch('[^\n]+') do
      table.insert(lines, line)
   end
   return lines
end

return M
