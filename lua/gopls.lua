local lspconfig = require('lspconfig')
local lcutil = require('lspconfig/util')

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

lspconfig.gopls.setup{
  -- Debugging:
  -- cmd = {'gopls', '-logfile', '/tmp/gopls.log', '-rpc.trace'},
  cmd = {'gopls'},
  filetypes = {"go", "gomod", "gowork"},
  root_dir = lcutil.root_pattern("go.work", "go.mod"),
  capabilities = capabilities,
  settings = {
    gopls = {
      linksInHover = false,
      gofumpt = true,
      ['local'] = 'liftoff.io/',
      analyses = {
        unusedparams = false,
        infertypeargs = false,
      },
    },
  },
}

function organize_imports(timeout_ms)
  local params = vim.lsp.util.make_range_params()
  params.context = {only = {'source.organizeImports'}}
  local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params, timeout_ms)
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
      else
        vim.lsp.buf.execute_command(r.command)
      end
    end
  end
end
