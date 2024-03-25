local M = {}

--- @param fun fun(client, buffer)
--- @param opts? table {once = boolean, desc = string}
function M.on_attach(fun, opts)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {clear=false}),
    callback = function(event)
      if not (event.data and event.data.client_id) then
        return
      end
      local buffer = event.buf
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      fun(client, buffer)
    end,
    once = opts and opts.once == true,
    desc = opts and opts.desc,
  })
end

return M
