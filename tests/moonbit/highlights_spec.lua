local highlights = require('moonbit.highlights')

describe('highlights', function()
  local groups = {
    '@lsp.type.function_call.moonbit',
    '@lsp.type.function_decl.moonbit',
    '@lsp.typemod.function_call.async.moonbit',
    '@lsp.typemod.function_decl.async.moonbit',
    '@lsp.typemod.function_call.error.moonbit',
    '@lsp.typemod.function_decl.error.moonbit',
  }

  local function clear_groups()
    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, {})
    end
  end

  before_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, 'moonbit_highlights')
    clear_groups()
  end)

  after_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, 'moonbit_highlights')
    clear_groups()
  end)

  it('sets default semantic token modifier highlights', function()
    highlights.setup()

    assert.is_true(vim.api.nvim_get_hl(0, {
      name = '@lsp.typemod.function_call.async.moonbit',
    }).italic)
    assert.is_true(vim.api.nvim_get_hl(0, {
      name = '@lsp.typemod.function_decl.async.moonbit',
    }).italic)
    assert.is_true(vim.api.nvim_get_hl(0, {
      name = '@lsp.typemod.function_call.error.moonbit',
    }).underline)
    assert.is_true(vim.api.nvim_get_hl(0, {
      name = '@lsp.typemod.function_decl.error.moonbit',
    }).underline)
  end)

  it('does not color semantic token types as functions', function()
    highlights.setup()

    assert.is_nil(vim.api.nvim_get_hl(0, {
      name = '@lsp.type.function_call.moonbit',
      link = true,
    }).link)
    assert.is_nil(vim.api.nvim_get_hl(0, {
      name = '@lsp.type.function_decl.moonbit',
      link = true,
    }).link)
  end)

  it('registers a colorscheme refresh', function()
    highlights.setup()

    local autocmds = vim.api.nvim_get_autocmds({
      group = 'moonbit_highlights',
      event = 'ColorScheme',
    })
    assert.are.equal(1, #autocmds)
  end)

  it('does not override user highlight customizations', function()
    vim.api.nvim_set_hl(0, '@lsp.typemod.function_call.async.moonbit', {
      bold = true,
    })

    highlights.setup()
    vim.api.nvim_exec_autocmds('ColorScheme', {})

    local actual = vim.api.nvim_get_hl(0, {
      name = '@lsp.typemod.function_call.async.moonbit',
    })
    assert.is_true(actual.bold)
    assert.is_nil(actual.italic)
  end)
end)
