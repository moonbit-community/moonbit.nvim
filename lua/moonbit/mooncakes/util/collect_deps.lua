local M = {}

---@param bufnr number?
---@return table<string, {lnum: number, version: string}>
function M.collect_deps(bufnr)
  local res, in_deps, depth = {}, false, 0
  local lines = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)

  for i, line in ipairs(lines) do
    if not in_deps then
      if line:match('"deps"%s*:%s*{') then
        in_deps, depth = true, 1
      end
    else
      depth = depth
          + select(2, line:gsub("{", ""))
          - select(2, line:gsub("}", ""))
      if depth <= 0 then
        in_deps = false
      end
    end

    if in_deps then
      local pkg, ver = line:match('^%s*"([^"]+)"%s*:%s*"([^"]+)"()')
      if pkg and ver then
        res[pkg] = { lnum = i - 1, version = ver }
      end
    end
  end

  return res
end

return M
