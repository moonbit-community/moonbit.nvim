return {
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter = pcall(require, 'nvim-treesitter.parsers')
    local enable = treesitter_opts.enable or true
    if has_treesitter and enable then
      require 'moonbit.treesitter'.setup(treesitter_opts)
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'moonbit',
      callback = function(ev)
        vim.lsp.start({
          name = 'moonbit-lsp',
          cmd = { 'moonbit-lsp' },
          root_dir = vim.fs.root(ev.buf, { 'moon.mod.json' })
        })
      end
    })
  end
}
