local lspconfig = require('lspconfig')

-- I don't want diagnostics to show up at all except via the quickfix list.
vim.diagnostic.config({underline = false, virtual_text = false, signs = false})

-- Set up LSP key bindings.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    local opts = {buffer = ev.buf, silent = true}
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    -- Make the existing <leader>nn shortcut clear both reference highlights and
    -- normal search highlights.
    vim.keymap.set(
      'n',
      '<leader>nn',
      '<cmd> lua vim.lsp.buf.clear_references()<CR>:noh<CR>',
      opts
    )

    vim.keymap.set('n', '<leader>gh', vim.lsp.buf.document_highlight, opts)
    vim.keymap.set('n', '<leader>gi', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>gf', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>gr', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ga', vim.lsp.buf.code_action, opts)
    vim.keymap.set(
      'n',
      '<leader>gd',
      '<cmd> lua vim.diagnostic.setqflist{open=false}<CR>:FocusQuickfix<CR>',
      opts
    )
  end,
})
