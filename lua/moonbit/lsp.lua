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

---@param uri string
---@return integer
local function ensure_loaded_buffer(uri)
  local bufnr = vim.uri_to_bufnr(uri)
  if bufnr == -1 then
    local file = vim.uri_to_fname(uri)
    bufnr = vim.fn.bufadd(file)
  end
  vim.fn.bufload(bufnr)
  return bufnr
end

---@param uri string
---@param line integer
---@return string
local function get_line(uri, line)
  local bufnr = ensure_loaded_buffer(uri)
  local lines = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)
  return lines[1] or ''
end

---@param changes table<string, lsp.TextEdit[]>
---@param uri string
---@param edit lsp.TextEdit
local function push_edit(changes, uri, edit)
  if changes[uri] == nil then
    changes[uri] = {}
  end
  table.insert(changes[uri], edit)
end

---@param changes table<string, lsp.TextEdit[]>
---@param loc lsp.Location
---@param can_add_priv boolean
local function push_hide_edits(changes, loc, can_add_priv)
  local start_line = loc.range.start.line
  local line = get_line(loc.uri, start_line)
  local pub_prefix = line:match('^(%s*pub%s*%(%w+%)%s*)') or
      line:match('^(%s*pub%s*)')
  if pub_prefix ~= nil then
    push_edit(changes, loc.uri, {
      range = {
        start = { line = start_line, character = 0 },
        ['end'] = { line = start_line, character = #pub_prefix },
      },
      newText = can_add_priv and 'priv ' or '',
    })
  elseif line:find('^%s*priv%s*') ~= nil then
    return
  elseif can_add_priv then
    push_edit(changes, loc.uri, {
      range = {
        start = { line = start_line, character = 0 },
        ['end'] = { line = start_line, character = 0 },
      },
      newText = 'priv ',
    })
  end
end

---@param changes table<string, lsp.TextEdit[]>
---@param loc lsp.Location
---@param prefix string
local function push_unhide_edits(changes, loc, prefix)
  local start_line = loc.range.start.line
  local line = get_line(loc.uri, start_line)
  local s, e = line:find('^%s*priv%s*')
  if s ~= nil and e ~= nil then
    push_edit(changes, loc.uri, {
      range = {
        start = { line = start_line, character = 0 },
        ['end'] = { line = start_line, character = e },
      },
      newText = prefix,
    })
  elseif line:find('^%s*pub%s*%(%w+%)%s*') ~= nil or
      line:find('^%s*pub%s*') ~= nil then
    return
  else
    push_edit(changes, loc.uri, {
      range = {
        start = { line = start_line, character = 0 },
        ['end'] = { line = start_line, character = 0 },
      },
      newText = prefix,
    })
  end
end

---@param command vim.lsp.Command
local function execute_mbti_hide(command)
  local arguments = command.arguments and command.arguments[1]
  if arguments == nil then
    return
  end
  local changes = {}
  local sig_loc = arguments.sigLoc
  push_edit(changes, sig_loc.uri, {
    range = {
      start = { line = sig_loc.range.start.line, character = 0 },
      ['end'] = { line = sig_loc.range.start.line, character = 0 },
    },
    newText = '#hidden\n',
  })
  for _, loc in ipairs(arguments.locations or {}) do
    push_hide_edits(changes, loc, arguments.canAddPriv)
  end
  vim.lsp.util.apply_workspace_edit({ changes = changes }, 'utf-16')
end

---@param command vim.lsp.Command
local function execute_mbti_unhide(command)
  local arguments = command.arguments and command.arguments[1]
  if arguments == nil then
    return
  end
  local changes = {}
  local attr_loc = arguments.attrLoc
  push_edit(changes, attr_loc.uri, {
    range = {
      start = { line = attr_loc.range.start.line, character = 0 },
      ['end'] = { line = attr_loc.range.start.line + 1, character = 0 },
    },
    newText = '',
  })
  for _, loc in ipairs(arguments.locations or {}) do
    push_unhide_edits(changes, loc, arguments.prefix)
  end
  vim.lsp.util.apply_workspace_edit({ changes = changes }, 'utf-16')
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
        vim.cmd [[edit]]
      end)
    end
    vim.schedule(function()
      local output = process.stdout or ''
      local lines = vim.split(output, '\n')
      local summary = lines[#lines - 1]
      if process.code == 0 then
        vim.notify('MoonBit: ' .. summary, vim.log.levels.INFO)
        return
      end
      vim.notify('MoonBit: ' .. summary, vim.log.levels.ERROR)
      vim.fn.setqflist({}, ' ', { lines = lines, efm = vim.bo.errorformat })
      vim.cmd[[copen]]
    end)
  end
  vim.system(args, { text = true }, on_test_exit)
end

return {
  on_attach = function(bufnr, opts)
    vim.lsp.start(vim.tbl_deep_extend("keep", opts or {}, {
      name = 'moonbit-lsp',
      cmd = { find_lsp_server() },
      root_dir = vim.fs.root(bufnr, { 'moon.mod.json' }),
      commands = {
        ['moonbit-lsp/test'] = function(command)
          local arguments = command.arguments[1]
          execute_moon_test(bufnr, arguments)
        end,
        ['moonbit-lsp/hide-mbti'] = execute_mbti_hide,
        ['moonbit-lsp/unhide-mbti'] = execute_mbti_unhide,
      },
    }))
  end
}
