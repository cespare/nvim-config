local lspconfig = require('lspconfig')
local lcutil = require('lspconfig/util')

lspconfig.gopls.setup{
	cmd = {'gopls'},
  filetypes = {"go", "gomod", "gowork"},
  root_dir = lcutil.root_pattern("go.work", "go.mod"),
  settings = {
    gopls = {
      linksInHover = false,
      gofumpt = true,
      ['local'] = 'liftoff.io/',
      analyses = {
        unusedparams = false,
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
