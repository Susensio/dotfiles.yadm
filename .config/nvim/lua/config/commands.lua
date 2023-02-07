-- Replace tabs and 4 spaces with 2 spaces
vim.api.nvim_create_user_command(
  "Force2Spaces",
  function(arg)
    range = '%'
    if arg.range>0 then
      range = "'<,'>"
    end
    -- Tabs to 4 spaces first
    vim.cmd(range .. [[s/\t/    /ge]])
    -- then 4 spaces to 2
    vim.cmd(range .. [[s;^\(\s\+\);\=repeat(' ', len(submatch(0))/2);ge]])
  end,
  {range = true}
)
