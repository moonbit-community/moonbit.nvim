local trim = function(s)
  return s:gsub('^%s*(.-)%s*$', '%1')
end

return {
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter = pcall(require, 'nvim-treesitter.parsers')
    local enabled = treesitter_opts.enabled or true
    if has_treesitter and enabled then
      require 'moonbit.treesitter'.setup(treesitter_opts)
    end

    if opts.lsp ~= false then
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'moonbit',
        group = vim.api.nvim_create_augroup("moonbit_lsp", { clear = true }),
        callback = function(ev)
          vim.lsp.start(vim.tbl_deep_extend("keep", opts.lsp or {}, {
            name = 'moonbit-lsp',
            cmd = { 'moonbit-lsp' },
            root_dir = vim.fs.root(ev.buf, { 'moon.mod.json' }),
            commands = {
              ['moonbit-lsp/test'] = function(command, ctx)
                local arguments = command.arguments[1]
                local stdout = vim.uv.new_pipe()
                local stderr = vim.uv.new_pipe()
                local args = {
                  'test',
                  '--target=' .. arguments.backend,
                  '-p',
                  arguments.pkgPath,
                  '-f',
                  arguments.fileName,
                  '-i',
                  tostring(arguments.index),
                }
                if arguments.update then
                  table.insert(args, '-u')
                end
                local handle, pid = vim.uv.spawn('moon', {
                  args = args,
                  cwd = arguments.cwdUri:sub(7, -1),
                  stdio = { nil, stdout, stderr }
                }, function()
                  stdout:close()
                  stderr:close()
                  vim.schedule(function()
                    vim.api.nvim_buf_call(ev.buf, function()
                      vim.cmd [[edit]]
                    end)
                  end)
                  -- print('exit code', code)
                end)
                vim.uv.read_start(stdout, function(err, data)
                  assert(not err, err)
                  if not data then
                    return
                  end
                  local trimmed = trim(data)
                  if trimmed ~= "" then
                    print(trimmed)
                  end
                end)
              end,
            },
          }))
        end,
      })
    end
  end
}
