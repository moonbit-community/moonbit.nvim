local M = {}

local semantic_token_highlights = {
  ['@lsp.typemod.function_call.async.moonbit'] = { italic = true, default = true },
  ['@lsp.typemod.function_decl.async.moonbit'] = { italic = true, default = true },
  ['@lsp.typemod.function_call.error.moonbit'] = { underline = true, default = true },
  ['@lsp.typemod.function_decl.error.moonbit'] = { underline = true, default = true },
}

local function apply()
  for group, opts in pairs(semantic_token_highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('moonbit_highlights', { clear = true })
  apply()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = apply,
  })
end

return M
