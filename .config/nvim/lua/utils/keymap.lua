local M = {}

function M.set(mode, lhs, rhs, opts)
   local options = { }
   if opts then
      options = vim.tbl_extend("force", options, opts)
   end
   if rhs == nil then rhs = "<Nop>" end
   vim.keymap.set(mode, lhs, rhs, options)
end

local augroup_filetype = vim.api.nvim_create_augroup("FileTypeKeymaps", { clear = true })
function M.set_per_filetype(filetype, mode, lhs, rhs, opts)
   opts = vim.tbl_extend("force", opts, { buffer = true })
   vim.api.nvim_create_autocmd("FileType", {
      desc = opts.desc,
      pattern = filetype,
      callback = function(event)
         -- BUG: rhs sometimes expect buf, sometimes do not, and sometimes is a string...
         -- vim.keymap.set(mode, lhs, function() rhs(buf) end, opts)
         M.set(mode, lhs, rhs, opts)
      end,
      group = augroup_filetype,
   })
end

--Returns a dot repeatable version of a function to be used in keymaps
--that pressing `.` will repeat the action.
-- https://www.reddit.com/r/neovim/comments/187q9ns/repeat_a_custom_command/
--Example: `vim.keymap.set('n', 'ct', dot_repeat(function() print(os.clock()) end), { expr = true })`
--Setting expr = true in the keymap is required for this function to make the keymap repeatable
local function dot_repeat(callback)
   return function()
      _G.dot_repeat_callback = callback
      vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
      return 'g@l'
   end
end


function M.set_repeatable(mode, lhs, rhs, opts)
   M.set(
      mode,
      lhs,
      dot_repeat(rhs),
      vim.tbl_extend("force", opts, { expr = true })
   )
end


return M
