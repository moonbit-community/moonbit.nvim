describe('lsp', function()
  local original_lsp_config
  local original_lsp_enable
  local original_lsp_start
  local original_moon_home
  local captured_config
  local started_config
  local tmpdirs

  local function fresh_lsp()
    package.loaded['moonbit.lsp'] = nil
    return require('moonbit.lsp')
  end

  local function make_moon_home(executable_name)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir .. '/bin', 'p')
    local executable = dir .. '/bin/' .. executable_name
    vim.fn.writefile({ '#!/bin/sh' }, executable)
    vim.fn.setfperm(executable, 'rwxr-xr-x')
    table.insert(tmpdirs, dir)
    vim.env.MOON_HOME = dir
    return vim.fn.resolve(executable)
  end

  before_each(function()
    original_lsp_config = vim.lsp.config
    original_lsp_enable = vim.lsp.enable
    original_lsp_start = vim.lsp.start
    original_moon_home = vim.env.MOON_HOME
    captured_config = nil
    started_config = nil
    tmpdirs = {}

    vim.lsp.config = function(name, config)
      captured_config = {
        name = name,
        config = config,
      }
    end
    vim.lsp.enable = function() end
    vim.lsp.start = function(config)
      started_config = config
    end
  end)

  after_each(function()
    vim.lsp.config = original_lsp_config
    vim.lsp.enable = original_lsp_enable
    vim.lsp.start = original_lsp_start
    vim.env.MOON_HOME = original_moon_home
    package.loaded['moonbit.lsp'] = nil

    for _, dir in ipairs(tmpdirs) do
      vim.fn.delete(dir, 'rf')
    end
  end)

  it('uses the legacy server by default', function()
    local legacy_lsp = make_moon_home('lsp-server.js')

    fresh_lsp().setup({})

    assert.are.equal('moonbit-lsp', captured_config.name)
    assert.are.same({ legacy_lsp }, captured_config.config.cmd)
    assert.is_nil(captured_config.config.native)
  end)

  it('uses moon-lsp when native is enabled', function()
    local native_lsp = make_moon_home('moon-lsp')

    fresh_lsp().setup({ native = true })

    assert.are.same({ native_lsp, '--stdio' }, captured_config.config.cmd)
    assert.is_nil(captured_config.config.native)
  end)

  it('lets explicit cmd override native discovery', function()
    make_moon_home('moon-lsp')

    fresh_lsp().setup({
      native = true,
      cmd = { 'custom-lsp' },
    })

    assert.are.same({ 'custom-lsp' }, captured_config.config.cmd)
  end)

  it('uses the configured command for non-moonbit buffers', function()
    local native_lsp = make_moon_home('moon-lsp')
    local lsp = fresh_lsp()
    local buf = vim.api.nvim_create_buf(false, true)

    lsp.setup({ native = true })
    vim.bo[buf].filetype = 'json'
    lsp.on_attach(buf)

    assert.are.same({ native_lsp, '--stdio' }, started_config.cmd)

    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
