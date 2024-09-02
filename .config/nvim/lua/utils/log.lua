local M = {}


function M.trace(msg)
   vim.notify(msg, vim.log.levels.TRACE)
end

function M.debug(msg)
   vim.notify(msg, vim.log.levels.DEBUG)
end

function M.info(msg)
   vim.notify(msg, vim.log.levels.INFO)
end

function M.warn(msg)
   vim.notify(msg, vim.log.levels.WARN)
end

function M.error(msg)
   vim.notify(msg, vim.log.levels.ERROR)
end

---@param what string
---@param state boolean
function M.toggle(what, state)
   if state then
      M.info("Enabled " .. what)
   else
      M.warn("Disabled " .. what)
   end
end

return M
