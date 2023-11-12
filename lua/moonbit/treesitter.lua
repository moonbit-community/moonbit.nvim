local install_info = {
  ['moonbit'] = {
    url = 'https://github.com/bzy-debug/tree-sitter-moonbit',
    files = { 'src/parser.c', 'src/scanner.c' },
    branch = 'main',
  },
}

return {
  setup = function (opts)
    local has_treesitter, parsers = pcall(require, 'nvim-treesitter.parsers')
    if not has_treesitter then return end

    for filetype, install_info in pairs(install_info) do
      local opts = opts[filetype] or {}
      local enable = opts.enable or true
      if enable then
        opts.install_info = opts.install_info or install_info
        opts.filetype = opts.filetype or filetype
        parsers.get_parser_configs()[filetype] = opts
      end
    end
  end
}
