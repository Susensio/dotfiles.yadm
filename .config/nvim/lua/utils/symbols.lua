M = {}

M.diagnostics = {
   error = "",
   warn = "",
   info = "",
   hint = "󰌵",
}

M.spaced = setmetatable({}, {
   __index = function(_, key)
      return vim.tbl_map(function(x) return x.." " end, M[key])
   end
})

return M
