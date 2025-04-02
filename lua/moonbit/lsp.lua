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
      },
    }))
  end
}
