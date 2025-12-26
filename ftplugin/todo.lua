-- Set up custom folding.
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.todo_foldexpr()"
vim.opt_local.foldtext = "v:lua.todo_foldtext()"
vim.opt_local.foldlevel = 0 -- Start with all folds closed.

-- Remove the trailing fill characters (cdots) after fold lines.
vim.opt_local.fillchars:append({ fold = " " })

-- Trigger fold recalculation when leaving insert mode.
vim.api.nvim_create_autocmd("InsertLeave", {
  buffer = 0,
  callback = function()
    vim.wo.foldmethod = vim.wo.foldmethod
  end,
})

function _G.todo_foldexpr()
  local line = vim.fn.getline(vim.v.lnum)

  -- Headings are not folded.
  if line:match("^# ") then
    return "0"
  end

  -- Empty lines: end the fold (sections end at blank lines).
  if line:match("^%s*$") then
    return "0"
  end

  if line:match("^%s+") then
    -- Indented line: part of current section (fold level 1).
    return "1"
  else
    -- Non-indented, non-heading line: start of new section.
    return ">1"
  end
end

function _G.todo_foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  return "▶ " .. line:gsub("%s+$", "")
end

local function indent_todo_tree(op)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, old_col = pos[1], pos[2]
  local old_indent = vim.fn.indent(row)

  local last_row = vim.fn.line("$")
  local end_row = row

  for i = row + 1, last_row do
    local line = vim.fn.getline(i)
    local indent = vim.fn.indent(i)
    if line == "" or indent <= old_indent then
      break
    end
    end_row = i
  end

  local cmd = string.format("%d,%d%s", row, end_row, op)
  vim.cmd(cmd)

  -- Restore cursor position.
  local new_indent = vim.fn.indent(row)
  local new_col = math.max(0, old_col + new_indent - old_indent)
  vim.api.nvim_win_set_cursor(0, { row, new_col })
end

-- Set up buffer-local keymaps for indent/dedent subtree
vim.keymap.set("n", "<C-.>", function() indent_todo_tree(">") end, {
  buffer = true,
  desc = "Indent todo subtree"
})

vim.keymap.set("n", "<C-,>", function() indent_todo_tree("<") end, {
  buffer = true,
  desc = "Unindent todo subtree"
})
