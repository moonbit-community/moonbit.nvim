return {
  setup = function(opts)
    local parser_name = 'moonbit'
    vim.api.nvim_create_autocmd('User', { pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers')[parser_name] = {
          tier = 2,
          install_info = {
            url = 'https://github.com/moonbitlang/tree-sitter-moonbit',
            revision = '85938537ea369d271c0a3f7d472ad4e490cd0d94',
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
