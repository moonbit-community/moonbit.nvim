return {
  setup = function(opts)
    local parser_name = 'moonbit'
    vim.api.nvim_create_autocmd('User', { pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers')[parser_name] = {
          tier = 2,
          install_info = {
            url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
            revision = 'd8e16ae8edd42a62f8e45e1a3b621f9c1b2661fc',
            files = { 'src/parser.c', 'src/scanner.c' },
            branch = 'main',
          },
        }
      end})
    vim.treesitter.language.register(parser_name, { 'mbt' })
    local auto_install =  opts.auto_install or opts.auto_install == nil
    if auto_install then
      require'nvim-treesitter'.install { parser_name }
    end
  end,
}
