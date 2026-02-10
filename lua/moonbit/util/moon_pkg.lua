local M = {}

---@param line string
---@return string
local function strip_line_comment(line)
  local in_string = false
  local escaped = false

  for i = 1, #line do
    local c = line:sub(i, i)
    if in_string then
      if escaped then
        escaped = false
      elseif c == '\\' then
        escaped = true
      elseif c == '"' then
        in_string = false
      end
    else
      if c == '"' then
        in_string = true
      elseif c == '/' and line:sub(i + 1, i + 1) == '/' then
        return line:sub(1, i - 1)
      end
    end
  end

  return line
end

---@param s string
---@param ch string
---@return integer
local function count_char(s, ch)
  local _, count = s:gsub(vim.pesc(ch), '')
  return count
end

---@param bufnr integer
---@param row integer
---@return boolean
function M.in_import_block(bufnr, row)
  if row < 0 then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
  local in_import = false
  local pending_import = false
  local depth = 0

  for _, line in ipairs(lines) do
    local clean = strip_line_comment(line)

    if not in_import then
      if pending_import then
        if clean:find('{') then
          in_import = true
          pending_import = false
          depth = 0
        elseif clean:match('%S') then
          pending_import = false
        end
      end

      if not in_import then
        local rest = clean:match('^%s*import%s*(.*)$')
        if rest ~= nil then
          if rest:find('{') then
            in_import = true
            depth = 0
          else
            pending_import = true
          end
        end
      end
    end

    if in_import then
      depth = depth + count_char(clean, '{') - count_char(clean, '}')
      if depth <= 0 then
        in_import = false
        depth = 0
      end
    end
  end

  return in_import
end

---@param line string
---@return string|nil
---@return string|nil
function M.parse_import_entry(line)
  local clean = strip_line_comment(line)

  local pkg, alias = clean:match('^%s*"([^"]+)"%s+as%s+@([%w_/%-]+)%s*,?%s*$')
  if pkg ~= nil then
    return pkg, alias
  end

  local plain = clean:match('^%s*"([^"]+)"%s*,?%s*$')
  if plain ~= nil then
    return plain, nil
  end

  return nil, nil
end

---@param content string
---@return boolean
function M.parse_is_main(content)
  local lines = vim.split(content, '\n', { plain = true })
  for i, line in ipairs(lines) do
    lines[i] = strip_line_comment(line)
  end
  local normalized = table.concat(lines, '\n')

  if normalized:match([["is%-main"%s*:%s*true]]) or normalized:match([["is_main"%s*:%s*true]]) then
    return true
  end

  return false
end

return M
