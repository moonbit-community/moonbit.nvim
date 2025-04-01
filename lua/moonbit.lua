local trim = function(s)
  return s:gsub('^%s*(.-)%s*$', '%1')
end

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
    vim.go.operatorfunc = "v:lua.require'moonbit'.api.toggle_multiline_string_operatorfunc"
    return 'g@'
  end, {
    buffer = buffer,
    desc = 'Toggle multiline string',
    expr = true,
  })
  vim.keymap.set({ 'n', 'x' }, '<Plug>(MoonBitToggleMultilineInterpolation)', function()
    vim.go.operatorfunc = "v:lua.require'moonbit'.api.toggle_multiline_interpolation_operatorfunc"
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

local path_sep = package.config:sub(1, 1)

---@return string
local function find_lsp_server()
  local moon_home = vim.env["MOON_HOME"]
  if moon_home == nil then
    local home = vim.env["HOME"]
    if home == nil then
      home = '~'
    end
    moon_home = home .. path_sep .. '.moon'
  end
  local lsp_server_path = vim.fn.resolve(moon_home .. path_sep .. 'bin' .. path_sep .. 'lsp-server.js')
  if vim.fn.executable(lsp_server_path) ~= 0 then
    return lsp_server_path
  end
  return 'moonbit-lsp'
end

---@class MoonBit.LSP.Commands.Test
---@field backend string
---@field pkgPath string
---@field fileName string
---@field index integer
---@field update boolean
---@field cwdUri string

---@param buffer integer
---@param arguments MoonBit.LSP.Commands.Test
local function execute_moon_test(buffer, arguments)
  local args = {
    'moon',
    'test',
    '--no-render',
    '--target=' .. arguments.backend,
  }
  if arguments.pkgPath ~= nil then
    table.insert(args, '-p')
    table.insert(args, arguments.pkgPath)
  end
  if arguments.fileName ~= nil then
    table.insert(args, '-f')
    table.insert(args, arguments.fileName)
  end
  if arguments.index ~= nil then
    table.insert(args, '-i')
    table.insert(args, tostring(arguments.index))
  end
  if arguments.update then
    table.insert(args, '-u')
  end
  ---@param process vim.SystemCompleted
  local function on_test_exit(process)
    if arguments.update then
      vim.schedule(function()
        vim.cmd[[edit]]
      end)
    end
    if process.code == 0 then
      return
    end
    local test_errorformats = { '%Etest %o failed: FAILED: %f:%l:%c-%e:%k %m', '%Etest %o failed',
      '%-Cexpect test failed at %f:%l:%c-%e:%k' }
    local test_errorformat = table.concat(test_errorformats, ',')
    vim.schedule(function()
      local output = process.stdout .. '\n' .. process.stderr
      local lines = vim.split(output, '\n')
      local errorformat = test_errorformat .. ',' .. vim.bo.errorformat
      vim.fn.setqflist({}, ' ', { lines = lines, efm = errorformat })
    end)
  end
  vim.system(args, { text = true }, on_test_exit)
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
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local enabled = treesitter_opts.enabled or true
    if enabled then
      require 'moonbit.treesitter'.setup(treesitter_opts)
    end

    -- add plenary filetype
    local has_plenary = pcall(require, "plenary")
    if has_plenary then
      require("plenary.filetype").add_file("moonbit")
    end

    if opts.lsp ~= false then
      local function on_attach(ev)
        setup_toggle_multiline_string(ev.buf)
        vim.cmd [[compiler moon]]
        vim.lsp.start(vim.tbl_deep_extend("keep", opts.lsp or {}, {
          name = 'moonbit-lsp',
          cmd = { find_lsp_server() },
          root_dir = vim.fs.root(ev.buf, { 'moon.mod.json' }),
          commands = {
            ['moonbit-lsp/test'] = function(command)
              local arguments = command.arguments[1]
              execute_moon_test(ev.buf, arguments)
            end,
          },
        }))
      end

      local moonbit_lsp_group = vim.api.nvim_create_augroup('moonbit.lsp', { clear = true });

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'moonbit',
        group = moonbit_lsp_group,
        callback = on_attach,
      })
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = { 'moon.pkg.json', 'moon.mod.json', },
        group = moonbit_lsp_group,
        callback = on_attach,
      })
    end
  end
}
