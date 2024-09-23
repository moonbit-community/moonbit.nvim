return {
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter = pcall(require, 'nvim-treesitter.parsers')
    local enabled = treesitter_opts.enabled or true
    if has_treesitter and enabled then
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
