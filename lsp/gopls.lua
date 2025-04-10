-- Turn off markdown in hover responses. This isn't handled correctly by nvim
-- and it displays escaping characters -- for example, this markdown:
--
--   See the documentation for \[Unmarshal] for details about
--
-- The [ is escaped because otherwise "[Unmarshal]" would be interpreted as a
-- link reference in Markdown. But nvim just displays the \ as-is.
-- TODO: Figure this out -- ISTM that nvim ought to handle this.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.hover.contentFormat = {"plaintext"}
capabilities.textDocument.signatureHelp.documentationFormat = {"plaintext"}

function format_go()
  local params = vim.lsp.util.make_range_params(0, "utf-8")
  params.context = {only = {"source.organizeImports"}}
  local timeout_ms = 1000
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout)
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
      end
    end
  end
  vim.lsp.buf.format({async = false})
end

vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*.go", callback = format_go})

return {
  -- Debugging:
  -- cmd = {"gopls", "-logfile", "/tmp/gopls.log", "-rpc.trace"},
  cmd = {"gopls"},
  root_markers = {"go.mod", "go.work"},
  filetypes = {"go", "gomod", "gowork"},
  capabilities = capabilities,
  settings = {
    gopls = {
      linksInHover = false,
      experimentalPostfixCompletions = false,
      gofumpt = true,
      ['local'] = 'liftoff.io/',
      analyses = {
        unusedparams = false,
        infertypeargs = false,
        modernize = false,
      },
    },
  },
}
