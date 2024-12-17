local stringx = require("stringx")

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

local errlist_type_map = {
  [vim.diagnostic.severity.ERROR] = 'E',
  [vim.diagnostic.severity.WARN] = 'W',
  [vim.diagnostic.severity.INFO] = 'I',
  [vim.diagnostic.severity.HINT] = 'N',
}

function sort_qflist_items(d0, d1)
  if d0.bufnr ~= d1.bufnr then
    -- Put the current buffer first.
    local curnr = vim.api.nvim_get_current_buf()
    if d0.bufnr == curnr then return true end
    if d1.bufnr == curnr then return false end
    -- Put loaded buffers first.
    local loaded0 = vim.api.nvim_buf_is_loaded(d0.bufnr)
    local loaded1 = vim.api.nvim_buf_is_loaded(d1.bufnr)
    if loaded0 ~= loaded1 then return loaded0 end
    -- Put test buffers last.
    local name0 = vim.api.nvim_buf_get_name(d0.bufnr)
    local name1 = vim.api.nvim_buf_get_name(d1.bufnr)
    local test0 = stringx.ends(name0, "_test.go")
    local test1 = stringx.ends(name1, "_test.go")
    if test0 ~= test1 then return test1 end
    -- Otherwise, order by filename.
    return name0 < name1
  end
  if d0.lnum ~= d1.lnum then return d0.lnum < d1.lnum end
  if d0.col ~= d1.col then return d0.col < d1.col end
  return false
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

    -- I only want to show diagnostics via the quickfix list, and only when
    -- requested. In particular, <leader>gd should populate the quickfix list
    -- and then open and focus it, but only if there are diagnostics to show.
    -- LSP servers like gopls tend to report diagnostics for the whole project
    -- (module in the gopls case), not just for the files that are open. That
    -- can be useful, but can also be annoying if working in a module that
    -- contains some unrelated, broken code. Therefore, the main <leader>gd
    -- binding filters just the diagnostics for the currently-open buffers and a
    -- second binding, <leader>gpd (mnemonic: "project diagnostics"), shows all
    -- the diagnostics.
    --
    -- Additionally, by default, simply using vim.diagnostic.seqflist populates
    -- the diagnostics in a nondeterministic order, so my versions also sort
    -- them properly.
    get_buffer_diagnostics = function(project_wide)
      -- This function also replicates part of vim.diagnostic.toqflist because
      -- that function does (unwanted) sorting.
      local items = {}
      for _, d in ipairs(vim.diagnostic.get(nil)) do
        if project_wide or vim.api.nvim_buf_is_loaded(d.bufnr) then
          local item = {
            bufnr = d.bufnr,
            lnum = d.lnum + 1,
            col = d.col and (d.col + 1) or nil,
            end_lnum = d.end_lnum and (d.end_lnum + 1) or nil,
            end_col = d.end_col and (d.end_col + 1) or nil,
            text = d.message,
            type = errlist_type_map[d.severity] or 'E',
          }
          table.insert(items, item)
        end
      end
      table.sort(items, sort_qflist_items)
      vim.fn.setqflist( {}, ' ', {title = 'Diagnostics', items = items})
    end
    vim.keymap.set(
      'n',
      '<leader>gd',
      '<cmd>lua get_buffer_diagnostics(false)<CR>:FocusQuickfix<CR>',
      opts
    )
    vim.keymap.set(
      'n',
      '<leader>gpd',
      '<cmd>lua get_buffer_diagnostics(true)<CR>:FocusQuickfix<CR>',
      opts
    )
  end,
})

-- Set up nvim-treesitter.
local treesitter = require("nvim-treesitter.configs")
treesitter.setup({
  -- The comment parser highlights things like TODO and FIXME.
  ensure_installed = {"go", "comment", "vim", "vimdoc"},
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

local treesj = require("treesj")
treesj.setup({
  use_default_keymaps = false,
})

vim.keymap.set("n", "<leader>js", treesj.toggle)

-- Set up conform.nvim to provide format-on-save for a few different languages
-- other than Go. This is simpler to manage than using a bunch of different
-- language-specific plugins.
local conform = require("conform")
conform.setup({
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    python = {"ruff_format"},
    sh = {"shfmt"},
    clojure = {"cljfmt"},
    javascript = {"prettier"},
    typescript = {"prettier"},
    css = {"prettier"},
    less = {"prettier"},
  },
  formatters = {
    cljfmt = {
      -- Use my cljfmt (github.com/cespare/goclj/cljfmt), not the other one.
      inherit = false,
      command = "cljfmt",
      stdin = true,
    },
    shfmt = {
      inherit = false,
      command = "shfmt",
      args = function(_, ctx)
        local args = { "-filename", "$FILENAME" }
        local editorconfig = vim.fs.find(".editorconfig", {
          path = ctx.dirname,
          upward = true,
        })
        local has_editorconfig = editorconfig[1] ~= nil
        -- If there is an editorconfig, don't pass any args because shfmt will
        -- apply settings from there when no command line args are passed.
        if not has_editorconfig then
          vim.list_extend(args, {"-i", 2, "-ci"})
        end
        return args
      end,
    },
  },
})
