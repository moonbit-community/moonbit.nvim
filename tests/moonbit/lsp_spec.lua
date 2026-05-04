local lsp = require('moonbit.lsp')
local path_sep = package.config:sub(1, 1)
local tmp_paths = {}

local function mkdir(path)
  assert(vim.fn.mkdir(path, 'p') == 1)
end

local function touch_executable(path)
  assert(vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, path) == 0)
  assert(vim.fn.setfperm(path, 'rwxr-xr-x') == 1)
end

local function temp_moon_home(name)
  local path = vim.fn.resolve(vim.fn.tempname()) .. '-' .. name
  table.insert(tmp_paths, path)
  return path
end

local function lsp_server_executable_name()
  return vim.fn.has('win32') == 1 and 'moonbit-lsp.exe' or 'moonbit-lsp'
end

describe('lsp', function()
  local original_moon_home

  before_each(function()
    original_moon_home = vim.env.MOON_HOME
  end)

  after_each(function()
    vim.env.MOON_HOME = original_moon_home
    for _, path in ipairs(tmp_paths) do
      vim.fn.delete(path, 'rf')
    end
    tmp_paths = {}
    if vim.lsp and vim.lsp.enable then
      vim.lsp.enable('moonbit-lsp', false)
    end
  end)

  it('prefers the moonbit-lsp binary from MOON_HOME', function()
    if not (vim.lsp and vim.lsp.config) then
      return
    end

    local moon_home = temp_moon_home('with-lsp')
    local bin_dir = moon_home .. path_sep .. 'bin'
    local lsp_server = bin_dir .. path_sep .. lsp_server_executable_name()
    mkdir(bin_dir)
    touch_executable(lsp_server)
    touch_executable(bin_dir .. path_sep .. 'lsp-server.js')
    vim.env.MOON_HOME = moon_home

    lsp.setup({})

    assert.are.same({ lsp_server }, vim.lsp.config['moonbit-lsp'].cmd)
  end)

  it('falls back to moonbit-lsp on PATH when MOON_HOME has no binary', function()
    if not (vim.lsp and vim.lsp.config) then
      return
    end

    local moon_home = temp_moon_home('empty')
    mkdir(moon_home .. path_sep .. 'bin')
    vim.env.MOON_HOME = moon_home

    lsp.setup({})

    assert.are.same({ 'moonbit-lsp' }, vim.lsp.config['moonbit-lsp'].cmd)
  end)
end)
