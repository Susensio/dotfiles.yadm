local M = {}

local grp = vim.api.nvim_create_augroup("LazyNestedEvents", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

---Load a plugin lazily when a sequence of events is triggered.
---@param plugin string
---@param events string[]
function M.load_nested_events(plugin, events)
  if #events == 0 then
    return require("lazy.core.loader").load(plugin, { event = "Nested" })
  end
  local event = require("lazy.core.handler.event"):_parse(table.remove(events, 1))
  autocmd(event.event, {
    group = grp,
    pattern = event.pattern or "*",
    callback = function()
      M.load_nested_events(plugin, events)
    end,
  })
end
return M
