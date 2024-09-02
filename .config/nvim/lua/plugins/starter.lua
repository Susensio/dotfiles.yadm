local function header()
   return [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]]
end

return {
   { -- mini.starter
      "echasnovski/mini.starter",
      event = "VimEnter",
      enabled = true,
      cond = function()   -- only if nvim started without arguments
         return vim.fn.argc() == 0
      end,
      opts = function()
         local starter = require("mini.starter")
         local config = {
            header = header,
            items = {
               starter.sections.builtin_actions(),
               -- starter.sections.recent_files(10, false),      -- absolute
               starter.sections.recent_files(10, true),          -- relative
            },
            footer = "",
         }
         return config
      end,
      config = function(_, opts)
         -- close Lazy and re-open when starter is ready
         if vim.o.filetype == "lazy" then
            vim.cmd.close()
            vim.api.nvim_create_autocmd("User", {
               pattern = "MiniStarterOpened",
               callback = function()
                  require("lazy").show()
               end,
            })
         end

         local starter = require("mini.starter")
         starter.setup(opts)

         -- Footer with startup time
         vim.api.nvim_create_autocmd("User", {
            pattern = "LazyVimStarted",
            callback = function(ev)
               local stats = require("lazy").stats()
               local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
               local pad_footer = string.rep(" ", 8)
               starter.config.footer = pad_footer .. "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
               if vim.bo[ev.buf].filetype == "starter" then
                  pcall(starter.refresh)
               end
            end,
         })
      end,
   }
}
