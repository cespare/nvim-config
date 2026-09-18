-- This suite uses the normal config to exercise the actual Insert-mode maps.
vim.lsp.enable("gopls", false)
vim.o.debug = "msg"

local function body(lines)
  local result = {"package p", "func f() {"}
  vim.list_extend(result, lines)
  result[#result + 1] = "}"
  return result
end

local cases = {
  {
    name = "new raw string",
    before = body({"\tx := `"}),
    keys = "A<CR>text<CR>`<CR>next<Esc>",
    after = body({"\tx := `", "text", "`", "\tnext"}),
  },
  {
    name = "raw-string edits undo as one insertion",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>text<CR>`<CR>next<Esc>u",
    after = body({"\tx := `"}),
  },
  {
    name = "gomod brace insertion is unchanged",
    ft = "gomod",
    before = {"module example.com/p", "", "require ("},
    keys = "A<CR>example.com/q v1.2.3<Esc>",
    after = {"module example.com/p", "", "require (", "example.com/q v1.2.3", ")"},
  },
  {
    name = "normal-mode open line",
    before = body({"\tx := `"}),
    keys = "otext<Esc>",
    after = body({"\tx := `", "text"}),
  },
  {
    name = "unfinished string at EOF",
    before = {"package p", "func f() {", "\tx := `"},
    keys = "A<CR>text<CR>`<CR>next<Esc>",
    after = {"package p", "func f() {", "\tx := `", "text", "`", "\tnext"},
  },
  {
    name = "nested Go indentation",
    before = body({"\tif ok {", "\t\tx := `", "\t}"}),
    row = 4,
    keys = "A<CR>text<CR>`<CR>next<Esc>",
    after = body({"\tif ok {", "\t\tx := `", "text", "`", "\t\tnext", "\t}"}),
  },
  {
    name = "two-space Tab and literal autoindent",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>text<CR>next<CR>`<CR>code<Esc>",
    after = body({"\tx := `", "  text", "  next", "  `", "\tcode"}),
  },
  {
    name = "eight-space raw indent stays spaces on Enter",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab><Tab><Tab><Tab>text<CR>next<CR>`<CR>code<Esc>",
    after = body({"\tx := `", "        text", "        next", "        `", "\tcode"}),
  },
  {
    name = "raw punctuation keeps eight-space indentation",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab><Tab><Tab><Tab>}<CR>next<Esc>",
    after = body({"\tx := `", "        }", "        next"}),
  },
  {
    name = "splitting immediately after the opening backtick",
    before = body({"\tx := `text`"}),
    keys = "f`a<CR><Esc>",
    after = body({"\tx := `", "text`"}),
  },
  {
    name = "splitting an existing raw-string line",
    before = body({"\tx := `", "  ab", "`"}),
    row = 4,
    col = 3,
    keys = "i<CR><Esc>",
    after = body({"\tx := `", "  a", "  b", "`"}),
  },
  {
    name = "multiple strings and misleading backticks",
    before = body({"\ta := `first`", '\tb := "`" // `', "\tx := `"}),
    row = 5,
    keys = "A<CR><Tab>text<CR>`<CR>next<Esc>",
    after = body({
      "\ta := `first`",
      '\tb := "`" // `',
      "\tx := `",
      "  text",
      "  `",
      "\tnext",
    }),
  },
  {
    name = "raw text does not continue Go line comments",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>// text<CR>next<Esc>",
    after = body({"\tx := `", "  // text", "  next"}),
  },
  {
    name = "raw text does not continue Go block comments",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>/* text<CR>next<Esc>",
    after = body({"\tx := `", "  /* text", "  next"}),
  },
  {
    name = "normal Go comment continuation is restored",
    before = body({"\tx := `"}),
    keys = "A<CR>text<CR>`<CR>// comment<CR>next<Esc>",
    after = body({"\tx := `", "text", "`", "\t// comment", "\t// next"}),
  },
  {
    name = "Tab does not expand Go snippets in raw strings",
    before = body({"\tx := `"}),
    keys = "A<CR>ep<Tab>text<Esc>",
    after = body({"\tx := `", "ep  text"}),
  },
  {
    name = "Tab immediately after opening backtick",
    before = body({"\tx := `"}),
    keys = "A<Tab>x<Esc>",
    after = body({"\tx := `  x"}),
  },
  {
    name = "Tab before closing backtick",
    before = body({"\tx := `text`"}),
    keys = "$i<Tab><Esc>",
    after = body({"\tx := `text  `"}),
  },
  {
    name = "Tab after closing backtick stays a tab",
    before = body({"\tx := `text`"}),
    keys = "A<Tab>",
    after = body({"\tx := `text`\t"}),
  },
  {
    name = "empty raw string has no interior after its closing backtick",
    before = body({"\tx := ``"}),
    keys = "A<Tab>",
    after = body({"\tx := ``\t"}),
  },
  {
    name = "Go snippets outside raw strings still expand",
    before = body({"\tep"}),
    keys = "A<Tab>",
    after = body({"\tif err != nil {", "\t\tpanic(err)", "\t}"}),
  },
  {
    name = "raw braces do not insert Go braces",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>{<CR>text<Esc>",
    after = body({"\tx := `", "  {", "  text"}),
  },
  {
    name = "raw parentheses do not insert Go parentheses",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>(<CR>text<Esc>",
    after = body({"\tx := `", "  (", "  text"}),
  },
  {
    name = "closing braces in raw text do not dedent",
    before = body({"\tx := `"}),
    keys = "A<CR><Tab>text<CR>}<CR>next<Esc>",
    after = body({"\tx := `", "  text", "  }", "  next"}),
  },
  {
    name = "comments containing backticks are not raw strings",
    before = body({"\t// `"}),
    keys = "A<Tab>",
    after = body({"\t// `\t"}),
  },
  {
    name = "quoted backticks are not raw strings",
    before = body({'\tx := "`"'}),
    keys = "A<Tab>",
    after = body({'\tx := "`"\t'}),
  },
  {
    name = "unfinished quoted string is not a raw string",
    before = body({'\tx := "`'}),
    keys = "A<Tab>",
    after = body({'\tx := "`\t'}),
  },
  {
    name = "Go brace insertion outside raw strings",
    before = body({"\tif ok {"}),
    keys = "A<CR>next<Esc>",
    after = body({"\tif ok {", "\t\tnext", "\t}"}),
  },
  {
    name = "ordinary Go block indentation",
    before = body({"\tif ok {", "\t}"}),
    keys = "A<CR>next<Esc>",
    after = body({"\tif ok {", "\t\tnext", "\t}"}),
  },
  {
    name = "return from a multiline call",
    before = body({"\tf(", "\t\t`", "text", "`)"}),
    row = 6,
    keys = "A<CR>next<Esc>",
    after = body({"\tf(", "\t\t`", "text", "`)", "\tnext"}),
  },
  {
    name = "return from a composite literal",
    before = body({"\tx := T{", "\t\tS: `", "text", "`}"}),
    row = 6,
    keys = "A<CR>next<Esc>",
    after = body({"\tx := T{", "\t\tS: `", "text", "`}", "\tnext"}),
  },
  {
    name = "continue a multiline call",
    before = body({"\tf(", "\t\t`", "text", "`,", "\t)"}),
    row = 6,
    keys = "A<CR>next<Esc>",
    after = body({"\tf(", "\t\t`", "text", "`,", "\t\tnext", "\t)"}),
  },
}

for _, keys in ipairs({"gg=G", "ggVG="}) do
  cases[#cases + 1] = {
    name = "reindent ignores Go punctuation inside raw strings: " .. keys,
    before = body({
      "x := `",
      "  first",
      "    nested",
      "}",
      "case x:",
      "\tkeep this tab",
      "  `",
      "next",
    }),
    keys = keys,
    after = body({
      "\tx := `",
      "  first",
      "    nested",
      "}",
      "case x:",
      "\tkeep this tab",
      "  `",
      "\tnext",
    }),
  }
  -- Native = normalizes whitespace even when indentexpr returns -1, and
  -- strips whitespace-only lines without calling indentexpr at all.
  cases[#cases + 1] = {
    name = "native whitespace normalization remains unchanged: " .. keys,
    before = body({"x := `", "  ", "        text", " \tmixed", "`", "next"}),
    keys = keys,
    after = body({"\tx := `", "", "\ttext", "\tmixed", "`", "\tnext"}),
  }
end

local failed = 0
local count = 0
for _, buffer_map in ipairs({false, true}) do
  for _, case in ipairs(cases) do
    count = count + 1
    local ok, err = pcall(function()
      vim.snippet.stop()
      vim.cmd("enew!")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, case.before)
      vim.bo.filetype = case.ft or "go"
      if vim.bo.filetype == "go" then
        assert(vim.bo.indentexpr == "v:lua.require'goindent'.indent()")
      end
      vim.cmd("let &undolevels = &undolevels")
      if buffer_map then
        -- LspAttach binds this same callback buffer-locally.
        vim.keymap.set("i", "<Tab>", _G.snippet_tab_expand, {buffer = 0})
      end
      vim.v.errmsg = ""
      local fo = vim.bo.formatoptions
      vim.api.nvim_win_set_cursor(0, {case.row or 3, case.col or 0})
      vim.api.nvim_feedkeys(vim.keycode(case.keys), "xt", false)
      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(vim.v.errmsg == "", vim.v.errmsg)
      assert(vim.bo.formatoptions == fo, "formatoptions was not restored")
      assert(vim.deep_equal(actual, case.after), vim.inspect({
        expected = case.after,
        actual = actual,
      }))
    end)
    if not ok then
      failed = failed + 1
      print(case.name .. " (buffer map: " .. tostring(buffer_map) .. "): " .. err)
    end
  end
end

if failed > 0 then
  print(failed .. "/" .. count .. " checks failed")
  vim.cmd("cquit 1")
end
print(count .. " Go raw-string editing checks passed")
vim.cmd("qa!")
