return {
  setup = function(opts)
    local parser_name = 'moonbit'
    vim.api.nvim_create_autocmd('User', { pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers')[parser_name] = {
          install_info = {
            url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
            files = { 'src/parser.c', 'src/scanner.c' },
            branch = 'main',
            queries = 'queries',
          },
        }
      end})
    local auto_install =  opts.auto_install or opts.auto_install == nil
    if auto_install then
      require'nvim-treesitter'.install { parser_name }
    end
  end,
}
