local M = {}

local function context(row, col)
  local parser = assert(vim.treesitter.get_parser(0, "go"))
  local root = parser:parse()[1]:root()
  local query = vim.treesitter.query.parse("go", '"`" @tick')
  local first, last

  -- Pair delimiter tokens rather than raw_string_literal nodes: an unfinished
  -- string has its opening backtick and contents under an ERROR node. Backticks
  -- inside comments and quoted strings are not delimiter tokens.
  for _, node in query:iter_captures(root, 0, 0, row + 1) do
    if not node:missing() then
      local r, c = node:start()
      if r > row or (r == row and c >= col) then
        break
      end
      if first then
        if first < r then
          last = {first = first, row = r, node = node}
        end
        first = nil
      else
        first = r
      end
    end
  end
  return first, last
end

function M.in_raw_string()
  if vim.bo.filetype ~= "go" then
    return false
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local first = context(row - 1, col)
  return first ~= nil
end

function M.newline()
  if vim.bo.filetype ~= "go" then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local first = context(row - 1, col)
  if first == nil then
    return
  end
  local indent = ""
  if first < row - 1 then
    indent = vim.api.nvim_get_current_line():sub(1, col):match("^%s*")
  end
  -- Disable comment continuation just for this newline. Go's noexpandtab
  -- would also turn eight spaces of autoindent into a tab, so clear that
  -- autoindent with 0<C-D> and copy the literal whitespace ourselves.
  local disable = vim.keycode("<Cmd>setlocal formatoptions-=r<CR>")
  local restore = vim.keycode(
    "<Cmd>let &l:formatoptions = " .. vim.fn.string(vim.bo.formatoptions) .. "<CR>"
  )
  return disable .. "\n0" .. vim.keycode("<C-D>") .. indent .. restore
end

function M.indent()
  local lnum = vim.v.lnum
  local first, last = context(lnum - 1, 0)
  if first then
    local mode = vim.fn.mode(1)
    -- Start newly opened, empty lines flush left, but do not reset existing
    -- indentation during =, including visual-mode =.
    if lnum == first + 2
      and (mode == "i" or mode == "n")
      and vim.fn.getline(lnum):match("^%s*$") then
      return 0
    end
    return -1
  end

  local ind = vim.fn.GoIndent(lnum)
  local prev = vim.fn.prevnonblank(lnum - 1)
  if last and last.row == prev - 1 then
    local row = last.first
    local node = last.node:parent()
    -- A closing backtick can also finish a surrounding call or composite
    -- literal. Resume at that construct's indentation, not its argument's.
    while node do
      local r, _, e = node:range()
      if e == last.row and not node:has_error() then
        row = math.min(row, r)
      end
      node = node:parent()
    end
    ind = ind + vim.fn.indent(row + 1) - vim.fn.indent(prev)
  end
  return ind
end

return M
