-- TODO: Copied from nvim source code. Delete after I switch to 0.7.0+.
function pretty_print(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '    '))
  return ...
end

function delete_trailing_whitespace()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.api.nvim_win_set_cursor(0, pos)
end
