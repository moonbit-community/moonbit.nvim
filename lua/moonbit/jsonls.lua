local M = {}

local function find_schema_path(filename)
  local matches = vim.api.nvim_get_runtime_file('schemas/' .. filename, false)
  if matches == nil or #matches == 0 then
    return nil
  end
  return matches[1]
end

local function build_schema(name, file_match, filename, description)
  local path = find_schema_path(filename)
  if path == nil then
    return nil
  end
  return {
    description = description,
    fileMatch = { file_match },
    name = name,
    url = vim.uri_from_fname(path),
  }
end

local function moonbit_schemas()
  local schemas = {}
  local mod = build_schema(
    'moon.mod.json',
    'moon.mod.json',
    'mod.schema.json',
    'MoonBit Module JSON schema'
  )
  if mod ~= nil then
    table.insert(schemas, mod)
  end
  local pkg = build_schema(
    'moon.pkg.json',
    'moon.pkg.json',
    'pkg.schema.json',
    'MoonBit Package JSON schema'
  )
  if pkg ~= nil then
    table.insert(schemas, pkg)
  end
  return schemas
end

local function merge_schemas(existing, extras)
  local merged = {}
  if type(existing) == 'table' then
    for _, item in ipairs(existing) do
      table.insert(merged, item)
    end
  end
  if type(extras) == 'table' then
    for _, item in ipairs(extras) do
      table.insert(merged, item)
    end
  end
  return merged
end

local function merge_settings(existing, schemas, user_settings)
  local merged = vim.deepcopy(existing or {})
  merged.settings = merged.settings or {}
  merged.settings.json = merged.settings.json or {}

  merged.settings.json.schemas = merge_schemas(merged.settings.json.schemas, schemas)

  merged.settings.json.validate = merged.settings.json.validate or {}
  if merged.settings.json.validate.enable == nil then
    merged.settings.json.validate.enable = true
  end

  if type(user_settings) == 'table' then
    merged = vim.tbl_deep_extend('force', merged, { settings = user_settings })
  end

  return merged
end

local function get_existing_config()
  if vim.lsp and vim.lsp.config then
    return vim.lsp.config['jsonls']
  end

  local ok, lspconfig = pcall(require, 'lspconfig')
  if ok and lspconfig.configs and lspconfig.configs.jsonls then
    return lspconfig.configs.jsonls.config or lspconfig.configs.jsonls.default_config
  end

  return nil
end

local function apply_config(config)
  if vim.lsp and vim.lsp.config then
    vim.lsp.config('jsonls', config)
    return true
  end

  local ok, lspconfig = pcall(require, 'lspconfig')
  if ok and lspconfig.jsonls then
    lspconfig.jsonls.setup(config)
    return true
  end

  return false
end

function M.setup(opts)
  if opts == false then
    return
  end
  if type(opts) == 'table' and opts.enabled == false then
    return
  end

  local schemas = moonbit_schemas()
  if #schemas == 0 then
    return
  end

  local user_settings = nil
  if type(opts) == 'table' then
    user_settings = opts.settings
  end

  local existing = get_existing_config()
  local merged = merge_settings(existing, schemas, user_settings)
  apply_config(merged)
end

return M
