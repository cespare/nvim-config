local stringx = require("stringx")

-- Enable language servers.
vim.lsp.enable({"gopls"})

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
    local opts = {buffer = ev.buf, silent = true}
    -- Neovim sets K as the default for the hover action, but we disable K
    -- (because it brings up a man page) in init.vim. Re-enable it here.
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    -- Note the other default bindings (see https://neovim.io/doc/user/lsp.html):
    -- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
    -- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
    -- "grr" is mapped in Normal mode to vim.lsp.buf.references()
    -- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
    -- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
    -- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
    -- This one is a bit hard to type, so let's replace it with C-i.
    -- (Note that this requires terminal support to distinguish from Tab. It
    -- works with Neovim+ghostty.)
    -- TODO: Why doesn't this unmapping work?
    -- vim.keymap.del('i', '<C-s>', opts)
    vim.keymap.set('i', '<C-i>', vim.lsp.buf.signature_help, opts)
    -- Add other custom commands:
    vim.keymap.set('n', 'grh', vim.lsp.buf.document_highlight, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)

    -- Make the existing <leader>nn shortcut clear both reference highlights and
    -- normal search highlights.
    vim.keymap.set(
      'n',
      '<leader>nn',
      '<cmd> lua vim.lsp.buf.clear_references()<CR>:noh<CR>',
      opts
    )

    -- I only want to show diagnostics via the quickfix list, and only when
    -- requested. In particular, grd should populate the quickfix list and then
    -- open and focus it, but only if there are diagnostics to show.
    -- LSP servers like gopls tend to report diagnostics for the whole project
    -- (module in the gopls case), not just for the files that are open. That
    -- can be useful, but can also be annoying if working in a module that
    -- contains some unrelated, broken code. Therefore, the main grd binding
    -- filters just the diagnostics for the currently-open buffers and a second
    -- binding, gpd (mnemonic: "project diagnostics"), shows all the
    -- diagnostics.
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
      'grd',
      '<cmd>lua get_buffer_diagnostics(false)<CR>:FocusQuickfix<CR>',
      opts
    )
    vim.keymap.set(
      'n',
      'gpd',
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
    -- TODO: prettier is too slow.
    -- Configure it to only run with a key binding, not on save.
    -- javascript = {"prettier"},
    -- typescript = {"prettier"},
    -- css = {"prettier"},
    -- less = {"prettier"},
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

-- Set up oil.nvim.
require("oil").setup()
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
