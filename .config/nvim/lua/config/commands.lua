-- Replace tabs and 4 spaces with 2 spaces
local command = vim.api.nvim_create_user_command

command(
  "Force2Spaces",
  function(arg)
    local range = "%"
    if arg.range>0 then
      range = "'<,'>"
    end
    -- Tabs to 4 spaces first
    vim.cmd(range .. [[s/\t/    /ge]])
    -- then 4 spaces to 2
    vim.cmd(range .. [[s;^\(\s\+\);\=repeat(" ", len(submatch(0))/2);ge]])
  end,
  { range = true }
)

-- https://www.reddit.com/r/neovim/comments/zhweuc/whats_a_fast_way_to_load_the_output_of_a_command/
command(
  "Redir",
  function(ctx)
    local lines = vim.split(vim.api.nvim_exec(ctx.args, true), "\n", { plain = true })
    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
  end,
  { nargs = "+", complete = "command" }
)

command(
  "Grep",
  function(ctx)
    vim.cmd.grep({ ctx.args, bang = true, mods = { silent = true } })
    vim.cmd.copen()
  end,
  { nargs = "+" }
)

require("utils.lsp").on_attach(
  function(_, buf)
    vim.api.nvim_buf_create_user_command(buf, "Format",
      function(args)
        if args.range ~= 0 then
          vim.lsp.buf.format({ range = vim.lsp.util.make_given_range_params() })
        else
          vim.lsp.buf.format()
        end
      end,
      {
        desc = "Format code",
        range = "%",
      })
  end,
  { desc = "LSP format command" }
)

command(
  "Template",
  function(ctx)
    local template = ctx.args
    local template_path = vim.fn.stdpath("config").."/templates/"..template
    if vim.fn.filereadable(template_path) == 0 then
      print("Template not found: "..template)
      return
    end
    vim.cmd("0r "..template_path)
  end,
  {
    nargs = 1,
    -- complete with filenames in $HOME/.config/nvim/templates
    complete = function()
      local templates = vim.fn.globpath(vim.fn.stdpath("config").."/templates", "*", false, true)
      local filenames = vim.tbl_map(function(path)
        return vim.fn.fnamemodify(path, ":t")
      end, templates)
      return filenames
    end,
  }
)
