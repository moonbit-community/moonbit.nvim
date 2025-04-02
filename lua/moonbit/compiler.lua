return {
  on_attach = function(bufnr)
    vim.cmd [[compiler moon]]
  end
}
