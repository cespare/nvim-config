local lspconfig = require('lspconfig')

-- I don't want diagnostics to show up at all except via the quickfix list.
vim.diagnostic.config({underline = false, virtual_text = false, signs = false})

-- Use some monkey-patching to configure all floating windows (mostly used for
-- LSP features like hover). It's kind of hacky, but apparently this is how it's
-- done.
local prev_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or 'rounded'
  opts.max_width = opts.max_width or 80
  local bufnr, winnr = prev_util_open_floating_preview(contents, syntax, opts, ...)
  vim.api.nvim_win_set_option(winnr, "linebreak", true)
  return bufnr, winnr
end

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
    -- TODO: C-i and tab are indistinguishable by nvim using alacritty+tmux
    -- right now, so this binding breaks <tab>. There's a recent push for
    -- extending keyboard handling using special escape codes, largely pushed by
    -- kitty, and it is already adopted in neovim (but not alacritty or tmux).
    -- Once that's broadly implemented, this might work as-is.
    -- vim.keymap.set('i', '<C-i>', vim.lsp.buf.signature_help, opts)
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
