function format_go()
  -- Synchronously run gopls's source.organizeImports code action, then format.
  -- We drive the request ourselves (via the client-method API) instead of
  -- using vim.lsp.buf.code_action({apply = true}), because in nvim 0.12 that
  -- path still calls the deprecated dot-form client.request_sync internally.
  for _, client in ipairs(vim.lsp.get_clients({bufnr = 0, name = "gopls"})) do
    local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    params.context = {only = {"source.organizeImports"}, diagnostics = {}}
    local result = client:request_sync("textDocument/codeAction", params, 1000, 0)
    for _, r in pairs((result or {}).result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
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
  settings = {
    gopls = {
      linksInHover = false,
      experimentalPostfixCompletions = false,
      gofumpt = true,
      ['local'] = 'liftoff.io/',
      analyses = {
        unusedparams = false,
        unusedfunc = false,
        infertypeargs = false,
        deprecated = false,
        QF1002 = false,
        QF1003 = false,
        QF1004 = false,

        -- Disable all modernizers for now.
        any = false,
        appendclipped = false,
        bloop = false,
        forvar = false,
        mapsloop = false,
        minmax = false,
        omitzero = false,
        rangeint = false,
        reflecttypefor = false,
        slicescontains = false,
        slicesdelete = false,
        slicessort = false,
        stringscutprefix = false,
        stringsseq = false,
        testingcontext = false,
        waitgroup = false,
      },
    },
  },
}
