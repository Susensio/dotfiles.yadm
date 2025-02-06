local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local doautocmd = vim.api.nvim_exec_autocmds

local lsp = require("utils.lsp")
local loclist = require("utils.loclist")
local user_grp = augroup("UserGroup", { clear = true })

autocmd("TextYankPost", {
   desc = "Highlight on yank",
   callback = function()
      vim.highlight.on_yank({
         higroup = "IncSearch",
         timeout = 100
      })
   end,
   group = user_grp,
})

-- autocmd("BufWritePre", {
--    desc = "Remove trailing whitespace on save",
--    callback = function()
--       -- Save cursor position to later restore
--       local curpos = vim.api.nvim_win_get_cursor(0)
--       -- Search and replace trailing whitespace
--       vim.cmd([[keeppatterns %s/\s\+$//e]])
--       vim.api.nvim_win_set_cursor(0, curpos)
--    end,
--    group = user_grp,
-- })

autocmd("BufWinEnter", {
   desc = "Open help window in a vertical split if it fits better",
   pattern = {
      vim.fn.expand("$VIMRUNTIME") .. "/doc/*.txt",
      vim.fn.stdpath("state") .. "/lazy/readme/doc/*.{txt,md}",
      vim.fn.stdpath("data") .. "/lazy/*/doc/*.{txt,md}",
   },
   callback = function(ev)
      if not vim.bo[ev.buf].buftype == 'help' then
         return
      end
      -- First move to the very bottom
      vim.cmd.wincmd("J")
      local win_width = vim.api.nvim_win_get_width(0)
      local help_min_width = 78
      local more_than_double = win_width > 2 * help_min_width
      if more_than_double then
         -- Move the the very right
         vim.cmd.wincmd("L")
      end
   end,
   group = user_grp,
})

autocmd({ "VimResized" }, {
   desc = "Resize splits if window got resized",
   group = user_grp,
   callback = function()
      local current_tab = vim.fn.tabpagenr()
      vim.cmd("tabdo wincmd =")
      vim.cmd("tabnext " .. current_tab)
   end,
})

autocmd({ "BufWritePre" }, {
   desc = "Auto create dir when saving a file, in case some intermediate directory does not exist",
   group = user_grp,
   callback = function(event)
      if event.match:match("^%w%w+://") then
         return
      end
      local file = vim.uv.fs_realpath(event.match) or event.match
      vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
   end,
})

-- Diagnostics to location list
lsp.on_attach(
   function(client, buffer)
      -- BUG the first list is not being popullated
      autocmd({ "DiagnosticChanged", "WinEnter", "BufEnter" }, {
         -- buffer = buffer,
         desc = "Put diagnostics on location list",
         callback = function(event)
            local lsp_clients = vim.lsp.get_clients({ bufnr = event.buf })
            if #lsp_clients == 0 then
               return
            end

            local is_normal_mode = vim.fn.mode() == "n"
            if not is_normal_mode then
               return
            end

            -- vim.notify("Setting loclist from diagnostic.", vim.log.levels.INFO)
            local opened = loclist.is_visible()
            vim.diagnostic.setloclist({ open = opened })
         end,
         group = augroup("DiagnosticLocList", { clear = true }),
      })
   end,
   { desc = "LSP diagnostic to location list" }
)

-- respects 'viewoptions'
autocmd("BufWinLeave", {
   desc = "Save folds and cursor",
   pattern = "?*",
   command = "silent! mkview!",
   group = user_grp,
})

autocmd("BufWinEnter", {
   desc = "Load folds and cursor",
   pattern = "?*",
   command = "silent! loadview",
   group = user_grp,
})

autocmd({
   "WinEnter",
   "BufEnter",
   "FocusGained",
   -- "InsertLeave"
}, {
      desc = "Change visuals in focused window",
      pattern = "*",
      callback = function()
         if vim.opt_local.number:get() then
            vim.opt_local.relativenumber = true
         end
         vim.opt_local.cursorline = true
         doautocmd("User", { pattern = "FocusGained" })
      end,
      group = user_grp,
   })

autocmd({
   "WinLeave",
   "BufLeave",
   "FocusLost",
   -- "InsertEnter"
}, {
      desc = "Change visuals in unfocused window",
      pattern = "*",
      callback = function()
         if vim.opt_local.number:get() then
            vim.opt_local.relativenumber = false
         end
         -- not in neotree
         if not vim.tbl_contains({
            "neo-tree",
         }, vim.bo.filetype) then
            vim.opt_local.cursorline = false
         end
         doautocmd("User", { pattern = "FocusLost" })
      end,
      group = user_grp,
   })

-- vim.api.nvim_create_autocmd('BufReadPost', {
--    group = user_grp,
--    pattern = { '*' },
--    callback = function()
--       -- Sometimes buffer names become absolute paths and that messes up the
--       -- name in the tabline.
--       vim.cmd.lcd('.')
--    end,
-- })

autocmd("QuitPre", {
   desc = "Auto close some windows on exit",
   callback = function()
      vim.cmd.cclose()
      vim.cmd.lclose()
      -- check if command exists
      if vim.fn.exists(":OutlineClose") == 2 then
         vim.cmd({ cmd = "OutlineClose" })
      end
      if vim.fn.exists(":Neotree") == 2 then
         vim.cmd({ cmd = "Neotree", args = { "close" } })
      end
   end,
   group = user_grp,
   }
)

-- autocmd("WinClosed", {
--    callback = function()
--       vim.cmd("wincmd p")
--    end,
--    group = user_grp,
--    }
-- )
