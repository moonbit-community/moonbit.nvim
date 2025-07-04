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

function setup_moonbit_target()
  vim.api.nvim_create_user_command('MoonBitTarget', function(opts)
    local target = opts.args
    local valid  = { native = true, js = true, wasm = true, wasm_gc = true, llvm = true }
    if not valid[target] then
      vim.notify(("Invalid MoonBit target: %q (native/js/wasm)"):format(target),
        vim.log.levels.ERROR)
      return
    end

    local curr_win = vim.api.nvim_get_current_win()
    local curr_buf = vim.api.nvim_get_current_buf()

    vim.fn.jobstart({ 'moon', 'check', '--target', target }, {
      on_exit = function(_, exit_code)
        vim.schedule(function()
          if exit_code == 0 then
            for _, client in ipairs(vim.lsp.get_clients()) do
              if client.name:match('moonbit') then
                client.stop()
              end
            end

            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf)
                  and vim.bo[buf].buflisted then
                vim.api.nvim_buf_call(buf, function()
                  vim.cmd('silent! edit')
                end)
              end
            end

            if vim.api.nvim_win_is_valid(curr_win) then
              vim.api.nvim_set_current_win(curr_win)
            end
            if vim.api.nvim_buf_is_valid(curr_buf) then
              vim.api.nvim_set_current_buf(curr_buf)
            end

            vim.notify(("moonbit target switched to %s"):format(target),
              vim.log.levels.INFO)
          else
            vim.notify(("moon check failed (exit code %d)"):format(exit_code),
              vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end, {
    nargs    = 1,
    desc     = 'Mbt: switch moonbit target (native/llvm/js/wasm/wasm_gc) and restart LSP',
    complete = function(lead)
      return vim.tbl_filter(function(t) return vim.startswith(t, lead) end,
        { 'native', 'js', 'wasm', 'llvm', 'wasm_gc' })
    end,
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
    setup_moonbit_target()
    vim.cmd [[syntax match MoonBitBlockLine "///| "ms=s+3 conceal cchar= ]]
  end
}
