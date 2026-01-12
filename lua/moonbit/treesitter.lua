return {
  setup = function(opts)
    local auto_install = opts.auto_install ~= false
    
    -- Check if nvim-treesitter is available
    local has_treesitter, nvim_treesitter = pcall(require, 'nvim-treesitter')
    if not has_treesitter then return end

    -- Register moonbit language
    vim.treesitter.language.register('moonbit', 'moonbit')

    -- Register moonbit parser using the new API
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers').moonbit = {
          install_info = {
            url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
            revision = 'a5a7e0b9cb2db740cfcc4232b2f16493b42a0c82',
            files = { 'src/parser.c', 'src/scanner.c' },
            branch = 'main',
          },
        }
      end
    })

    -- Auto-install if requested
    if auto_install then
      local has_parser = pcall(vim.treesitter.language.add, 'moonbit')
      if not has_parser then
        nvim_treesitter.install({ 'moonbit' })
      end
    end
  end,
}
