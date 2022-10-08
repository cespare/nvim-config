local stringx = require("stringx")
local a = vim.api

function echom(...)
  vim.api.nvim_echo({{table.concat({...}, " ")}}, true, {})
end

function delete_trailing_whitespace()
  local pos = a.nvim_win_get_cursor(0)
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  a.nvim_win_set_cursor(0, pos)
end

function maybe_insert_closing_brace()
  local no = '\n'
  local n, col = unpack(a.nvim_win_get_cursor(0))
  n = n - 1 -- switch indexing schemes
  local lines = a.nvim_buf_get_lines(0, n, n+50, false)
  if #lines == 0 then
    return no
  end
  local cur = lines[1]
  if not stringx.ends(cur, '{') and not stringx.ends(cur, '(') then
    return no
  end
  local indent = cur:match('^%s*')
  for i = 2, #lines do
    local line = lines[i]
    if #line > 0 then
      if not stringx.starts(line, indent) then
        -- Found some text that's less indented. Insert close braces.
        break
      end
      line = line:sub(#indent + 1)
      if line:find('^%s') then
        -- Found some text that's more indented. Don't insert.
        return no
      end
      -- Found some text at the same level of indentation. If it starts with
      -- close braces, don't do anything; otherwise, insert close braces.
      if stringx.starts(line, '}') or stringx.starts(line, ')') then
        return no
      end
      break
    end
  end

  -- Going to insert some closing braces.
  -- Find all the unclosed ones and construct the reverse.
  local braces = {}
  for c in cur:gmatch('[%(%){}]') do
    if c == '(' or c == '{' then
      table.insert(braces, c)
    elseif c == ')' then
      if #braces > 0 and braces[#braces] == '(' then
        table.remove(braces)
      end
    elseif c == '}' then
      if #braces > 0 and braces[#braces] == '{' then
        table.remove(braces)
      end
    end
  end
  local closers = ''
  for i = #braces, 1, -1 do
    local b = braces[i]
    if b == '(' then
      b = ')'
    elseif b == '{' then
      b = '}'
    end
    closers = closers..b
  end
  return '\n'..closers..a.nvim_replace_termcodes('<C-O>O', true, false, true)
end
