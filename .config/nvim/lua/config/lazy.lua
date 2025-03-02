-- Automatically install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
   vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
   })
end
vim.opt.rtp:prepend(lazypath)

-- Properly load file based plugins without blocking the UI
-- stolen from LazyVim, waiting for a proper native implementation
-- https://github.com/folke/lazy.nvim/issues/1182
local function setup_lazy_file_event()
   local use_lazy_file = vim.fn.argc(-1) > 0
   local lazy_file_events = { "BufReadPost", "BufNewFile", "BufWritePre" }
   -- Add support for the LazyFile event
   local Event = require("lazy.core.handler.event")

   if use_lazy_file then
      -- We'll handle delayed execution of events ourselves
      Event.mappings.LazyFile = { id = "LazyFile", event = "User", pattern = "LazyFile" }
      Event.mappings["User LazyFile"] = Event.mappings.LazyFile
   else
      -- Don't delay execution of LazyFile events, but let lazy know about the mapping
      Event.mappings.LazyFile = { id = "LazyFile", event = lazy_file_events }
      Event.mappings["User LazyFile"] = Event.mappings.LazyFile
      return
   end

   local events = {} ---@type {event: string, buf: number, data?: any}[]

   local done = false
   local function load()
      if #events == 0 or done then
         return
      end
      done = true
      vim.api.nvim_del_augroup_by_name("lazy_file")

      ---@type table<string,string[]>
      local skips = {}
      for _, event in ipairs(events) do
         skips[event.event] = skips[event.event] or Event.get_augroups(event.event)
      end

      vim.api.nvim_exec_autocmds("User", { pattern = "LazyFile", modeline = false })
      for _, event in ipairs(events) do
         if vim.api.nvim_buf_is_valid(event.buf) then
            Event.trigger({
               event = event.event,
               exclude = skips[event.event],
               data = event.data,
               buf = event.buf,
            })
            if vim.bo[event.buf].filetype then
               Event.trigger({
                  event = "FileType",
                  buf = event.buf,
               })
            end
         end
      end
      vim.api.nvim_exec_autocmds("CursorMoved", { modeline = false })
      events = {}
   end

   -- schedule wrap so that nested autocmds are executed
   -- and the UI can continue rendering without blocking
   load = vim.schedule_wrap(load)

   vim.api.nvim_create_autocmd( lazy_file_events, {
      group = vim.api.nvim_create_augroup("lazy_file", { clear = true }),
      callback = function(event)
         table.insert(events, event)
         load()
      end,
   })
end

setup_lazy_file_event()

require("lazy").setup({
   spec = {
      { import = "plugins" },
      { import = "plugins.lang" }
   },
   defaults = {
      lazy = true,
      version = "*",
   },
   checker = {
      enabled = true,
      notify = false,
      frequency = 3600 * 20,  -- every 24h
   },
   change_detection = {
      enabled = true,
      notify = false,
   },
   install = {
      missing = true,
      colorscheme = { "monokai", "everforest", "habamax" },
   },
   dev = {
      path = '~/Workspace'
   },
   ui = {
      border = "rounded",
   },
   performance = {
      rtp = {
         disabled_plugins = {
            "gzip",
            "matchit",
            -- "netrwPlugin",
            "tarPlugin",
            "tohtml",
            "tutor",
            "zipPlugin",
         },
      },
   },
})
