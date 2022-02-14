local M = {}

M.starts = function(s, prefix)
  if #prefix > #s then
    return false
  end
  return s:sub(1, #prefix) == prefix
end

M.ends = function(s, suffix)
  if #suffix > #s then
    return false
  end
  return s:sub(-#suffix, -1) == suffix
end

return M
