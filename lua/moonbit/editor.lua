---@param lines string[]
local function remove_multiline_string(lines)
  local result = {}
  for _, line in ipairs(lines) do
    local leading, content = line:match('^(%s*)[#$]|([^\\n]*)')
    if content then
      table.insert(result, leading .. content)
    end
  end
  return result
end

---@param lines string[]
---@param separator string
local function insert_multiline_string(lines, separator)
  local result = {}
  for _, line in ipairs(lines) do
    table.insert(result, separator .. line)
  end
  return result
end

---@param lines string[]
---@param separator string
local function toggle_multiline_string(lines, separator)
  local is_multiline = true
  for _, line in ipairs(lines) do
    if not line:match('^%s*[#$]|') then
      is_multiline = false
      break
    end
  end
  if is_multiline then
    return remove_multiline_string(lines)
  else
    return insert_multiline_string(lines, separator)
  end
end

---@param buffer integer
---@param line1 integer
---@param line2 integer
---@param separator string
local function execute_toggle_multiline_string(buffer, line1, line2, separator)
  local lines = nil
  if line1 == line2 then
    lines = { vim.api.nvim_get_current_line() }
  else
    lines = vim.api.nvim_buf_get_lines(buffer, line1 - 1, line2, true)
  end
  lines = toggle_multiline_string(lines, separator)
  vim.api.nvim_buf_set_lines(buffer, line1 - 1, line2, true, lines)
end

---@param type 'char'|'line'|'block'
---@param separator '#|'|'$|'
local function toggle_multiline_string_operatorfunc(type, separator)
  if type ~= 'line' then
    error('Toggle multiline string only support line mode')
  end
  local buffer = vim.api.nvim_get_current_buf()
  local line1, line2 = vim.fn.line("'["), vim.fn.line("']")
  execute_toggle_multiline_string(buffer, line1, line2, separator)
end

---@param buffer integer
local function setup_toggle_multiline_string(buffer)
  vim.api.nvim_create_user_command('MoonBitToggleMultilineString', function(args)
    execute_toggle_multiline_string(buffer, args.line1, args.line2, '#|')
  end, {
    range = true,
  })
  vim.api.nvim_create_user_command('MoonBitToggleMultilineInterpolation', function(args)
    execute_toggle_multiline_string(buffer, args.line1, args.line2, '$|')
  end, {
    range = true,
  })
  vim.keymap.set({ 'n', 'x' }, '<Plug>(MoonBitToggleMultilineString)', function()
    vim.go.operatorfunc = "v:lua.require'moonbit.editor'.api.toggle_multiline_string_operatorfunc"
    return 'g@'
  end, {
    buffer = buffer,
    desc = 'Toggle multiline string',
    expr = true,
  })
  vim.keymap.set({ 'n', 'x' }, '<Plug>(MoonBitToggleMultilineInterpolation)', function()
    vim.go.operatorfunc = "v:lua.require'moonbit.editor'.api.toggle_multiline_interpolation_operatorfunc"
    return 'g@'
  end, {
    buffer = buffer,
    desc = 'Toggle multiline interpolation',
    expr = true,
  })
  vim.keymap.set({ 'n', 'x' }, '<LocalLeader>#|', '<Plug>(MoonBitToggleMultilineString)', {
    buffer = buffer,
    desc = 'Toggle multiline string',
  })
  vim.keymap.set({ 'n', 'x' }, '<LocalLeader>$|', '<Plug>(MoonBitToggleMultilineInterpolation)', {
    buffer = buffer,
    desc = 'Toggle multiline interpolation',
  })
end

return {
  api = {
    toggle_multiline_string_operatorfunc = function(type)
      toggle_multiline_string_operatorfunc(type, '#|')
    end,
    toggle_multiline_interpolation_operatorfunc = function(type)
      toggle_multiline_string_operatorfunc(type, '$|')
    end
  },
  on_attach = function(bufnr)
    setup_toggle_multiline_string(bufnr)
  end
}
