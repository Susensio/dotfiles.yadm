local M = {}

-- https://nanotipsforvim.prose.sh/using-pcall-to-make-your-config-more-stable
-- https://gist.github.com/beauwilliams/05c02c7b957615498fd39012316b791b
function M.safe(module)
  -- using xpcall instead of pcall for catching the stacktrace
  local success, result = xpcall(require, debug.traceback, module)
  if success then
    return result
  else
    -- local msg = debug.traceback("Error requiring " .. module .. "\n" .. result)
    local msg = "Error requiring " .. module .. "\n" .. result
    vim.schedule(function()
      -- vim.notify(msg, { title = 'Error loading module' })
      msg, _ = msg:gsub("[\t]", "        ")
      vim.api.nvim_err_writeln(msg)
    end)
    return nil
  end
end

-- From TJDevries
-- https://github.com/tjdevries/lazy-require.nvim
function M.lazy(module)
  return setmetatable({}, {
    __index = function(_, key)
      return require(module)[key]
    end,
    __newindex = function(_, key, value)
      require(module)[key] = value
    end,
  })
end

return M
