local M = {}

local grp = vim.api.nvim_create_augroup("LazyNestedEvents", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

---Load a plugin lazily when a sequence of events is triggered.
---@param plugin string
---@param events string[]
function M.load_on_nested_events(plugin, events)
   if #events == 0 then
      return require("lazy.core.loader").load(plugin, { event = "Nested" })
   end
   local event = require("lazy.core.handler.event"):_parse(table.remove(events, 1))
   autocmd(event.event, {
      group = grp,
      pattern = event.pattern or "*",
      callback = function()
         M.load_on_nested_events(plugin, events)
      end,
   })
end

---Execute a function when a plugin is loaded, or immediately if it is already loaded.
---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
   local Config = require("lazy.core.config")
   if Config.plugins[name] and Config.plugins[name]._.loaded then
      fn(name)
   else
      vim.api.nvim_create_autocmd("User", {
         group = grp,
         pattern = "LazyLoad",
         callback = function(event)
            if event.data == name then
               fn(name)
               return true
            end
         end,
      })
   end
end

---Load a plugin lazily when another plugin is loaded.
---@param plugin LazyPlugin
---@param dependency string
function M.load_on_load(plugin, dependency)
   M.on_load(dependency, function()
      require("lazy.core.loader").load(plugin, { event = "LazyLoad(" .. dependency .. ")" })
   end)
end

---Check if a plugin is loaded.
---@param plugin string
function M.has(plugin)
   return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

return M
