local stringx = require("stringx")

--------------------------------- Keymaps --------------------------------------

vim.keymap.set(
  "n",
  "<leader>$",
  function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
  end,
  { desc = "Delete trailing whitespace" }
)

vim.keymap.set("n", "<leader>f", "za", { desc = "Toggle fold under cursor" })
vim.keymap.set(
  "n",
  "<leader>F",
  function()
    -- Toggle between closing all folds (zM) and opening all folds (zR).
    -- If foldlevel is 0, all folds are closed, so open them.
    -- Otherwise, close all folds.
    if vim.wo.foldlevel == 0 then
      vim.cmd("normal! zR")
    else
      vim.cmd("normal! zM")
    end
  end,
  { desc = "Toggle all folds open/closed" }
)

vim.keymap.set(
  "n",
  "<leader>x",
  function()
    if vim.bo.buftype == "quickfix" then vim.cmd("wincmd p") end
    vim.cmd("silent! lclose")
    vim.cmd("silent! cclose")
  end,
  { desc = "Close the quickfix/loclist and jump back if inside" }
)

----------------------- Language servers ---------------------------------------

vim.lsp.enable({"gopls"})

-- I don't want diagnostics to show up at all except via the quickfix list.
vim.diagnostic.config({underline = false, signs = false})

-- Use rounded borders for all floating windows (hover, signature help, etc.).
vim.o.winborder = "rounded"

-- Monkey-patch open_floating_preview to:
--
-- 1. Set my preferred sizing/wrapping options (max_width, linebreak), since
--    winborder doesn't cover those.
--
-- 2. Pre-process markdown content from the LSP server before it's shown.
--    Both fixups are workarounds for the fact that nvim renders LSP markdown by
--    displaying the raw source text with treesitter-driven conceal extmarks on
--    top -- there's no real markdown rendering pass.
--
--    a. Strip URLs from inline links: `[text](url)` -> `[text]`. Gopls emits
--       these for every doc reference
--       (e.g. `[Marshaler.MarshalJSON](file:///.../encode.go#237,2)`),
--       and even though the URL portion is concealed visually, the buffer still
--       contains all those bytes. nvim's wrap+linebreak engine doesn't handle
--       wide concealed regions correctly: when a wrap falls inside one, the
--       literal space following the concealed region ends up at the start of
--       the next visual line instead of being absorbed at the end of the
--       previous one. Reducing the link to `[text]` (a CommonMark shortcut
--       link, with only the two brackets concealed) makes the concealed regions
--       tiny and the glitch effectively disappears.
--
--    b. Resolve CommonMark backslash escapes: `\X` -> `X` when X is ASCII
--       punctuation. Gopls emits `\[Foo]` to keep `[Foo]` from being parsed as
--       a link reference, and `\<` etc. for literal angle brackets. nvim's
--       markdown_inline treesitter query highlights `backslash_escape` nodes
--       but doesn't conceal them, so the leading `\` shows verbatim.
local prev_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.max_width = opts.max_width or 80
  if syntax == "markdown" and type(contents) == "table" then
    for i, line in ipairs(contents) do
      line = line:gsub("(%b[])%b()", "%1")  -- inline link -> shortcut link
      line = line:gsub("\\(%p)", "%1")      -- backslash-escape -> literal
      contents[i] = line
    end
  end
  local bufnr, winnr = prev_util_open_floating_preview(contents, syntax, opts, ...)
  vim.wo[winnr].linebreak = true
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
    -- The <C-i> mapping above is buffer-local. Most terminals send the same
    -- byte (0x09) for both <Tab> and <C-i>; Neovim only distinguishes them
    -- (via the kitty keyboard protocol) when both keys are mapped at the
    -- same scope. Since our <Tab> snippet mapping is global, we must also
    -- bind it buffer-locally here so that the protocol kicks in and <Tab>
    -- doesn't get swallowed by the buffer-local <C-i> mapping above.
    vim.keymap.set('i', '<Tab>', _G.snippet_tab_expand, opts)
    vim.keymap.set({'i', 's'}, '<S-Tab>', _G.snippet_shift_tab, opts)
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

------------------------------ Other plugins -----------------------------------

-- Set up nvim-treesitter. This requires tree-sitter (>=0.26.1) and a C compiler.
local treesitter = require("nvim-treesitter")
treesitter.setup()
-- The comment parser highlights things like TODO and FIXME inside comments
-- (via injection; see queries/lua/injections.scm for the Lua-specific override).
-- Other parsers we use (c, lua, markdown, markdown_inline, query, vim, vimdoc)
-- ship with Neovim, so they don't need to be listed here.
-- This call is async and a no-op when the listed parsers are already installed.
treesitter.install({"go", "comment"})

-- Enable treesitter highlighting only for Go.
-- The `comment` parser is attached automatically as an injected language.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function() vim.treesitter.start() end,
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
    javascript = {"biome"},
    typescript = {"biome"},
    css = {"biome"},
    -- TODO: prettier is too slow.
    -- Configure it to only run with a key binding, not on save.
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
        -- If there is an editorconfig, don't pass any other args because shfmt
        -- will apply settings from there when no command line args are passed.
        if not vim.fs.root(ctx.dirname, ".editorconfig") then
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

-- Define a Browse command for fugitive to use.
vim.api.nvim_create_user_command(
  "Browse",
  function (opts)
    vim.fn.system({"xdg-open", opts.fargs[1]})
  end,
  {nargs = 1}
)

-------------------------------- Snippets --------------------------------------

-- Snippet expansion using Neovim's built-in vim.snippet, with a snipmate-like
-- trigger-word + <Tab> workflow. Snippets themselves live in lua/snippets.lua.
local snippets = require("snippets")

local function tab_expand()
  -- If a snippet is currently active, jump to the next placeholder.
  if vim.snippet.active({ direction = 1 }) then
    return vim.snippet.jump(1)
  end
  -- Otherwise, see if the word before the cursor is a snippet trigger for
  -- the current filetype.
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local before = vim.api.nvim_get_current_line():sub(1, col)
  local word = before:match("([%w_]+)$")
  local body = word and (snippets[vim.bo.filetype] or {})[word]
  if body then
    -- Delete the trigger word, then expand.
    vim.api.nvim_buf_set_text(0, row - 1, col - #word, row - 1, col, { "" })
    vim.snippet.expand(body)
    return
  end
  -- Fall through: insert a literal Tab.
  vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
end

local function shift_tab()
  if vim.snippet.active({ direction = -1 }) then
    return vim.snippet.jump(-1)
  end
  vim.api.nvim_feedkeys(vim.keycode("<S-Tab>"), "n", false)
end

-- Expose so the LspAttach callback can also bind these buffer-locally; see
-- the comment there for why that's necessary.
_G.snippet_tab_expand = tab_expand
_G.snippet_shift_tab = shift_tab

vim.keymap.set(
  "i",
  "<Tab>",
  tab_expand,
  { desc = "Expand snippet, jump to next placeholder, or insert Tab" }
)
vim.keymap.set(
  { "i", "s" },
  "<S-Tab>",
  shift_tab,
  { desc = "Jump to previous snippet placeholder, or insert Shift-Tab" }
)
