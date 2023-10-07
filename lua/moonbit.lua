return {
  setup = function (opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter, parsers = pcall(require, 'nvim-treesitter.parsers')
    local enable = treesitter_opts.enable or true
    if has_treesitter and enable then
      require'moonbit.treesitter'.setup(treesitter_opts)
    end
  end
}
