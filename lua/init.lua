local treesitter = require("nvim-treesitter.configs")

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
    -- TODO: C-i would be a nicer mapping here, but C-i and tab are
    -- indistinguishable by terminals historically. Neovim and ghostty *should*
    -- both support the kitty keyboard protocol, but tmux doesn't yet, and even
    -- without tmux I can't seem to get the C-i mapping working without breaking
    -- tab.
    vim.keymap.set('i', '<C-f>', vim.lsp.buf.signature_help, opts)
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

-- Set up nvim-treesitter.
treesitter.setup({
  ensure_installed = {"go"},
  sync_install = true,
  auto_install = false,

  highlight = {
    enable = true,
    disable = function (lang, bufnr) return lang ~= "go" end,
    additional_vim_regex_highlighting = false,
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
})
