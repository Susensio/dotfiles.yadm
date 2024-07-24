local M = {}

--- @param fun fun(client, buffer)
--- @param opts? table {once = boolean, desc = string}
function M.on_attach(fun, opts)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = false }),
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


---@param from string
---@param to string
function M.on_rename(from, to)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({bufnr = bufnr})
  for _, client in ipairs(clients) do
    if client.supports_method("workspace/willRenameFiles") then
      ---@diagnostic disable-next-line: invisible
      local resp = client.request_sync("workspace/willRenameFiles", {
        files = {
          {
            oldUri = vim.uri_from_fname(from),
            newUri = vim.uri_from_fname(to),
          },
        },
      }, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end
end

return M
