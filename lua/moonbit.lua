return {
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter = pcall(require, 'nvim-treesitter.parsers')
    local enabled = treesitter_opts.enabled or true
    if has_treesitter and enabled then
      require 'moonbit.treesitter'.setup(treesitter_opts)
    end

    if opts.lsp ~= false then
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'moonbit',
        group = vim.api.nvim_create_augroup("moonbit_lsp", { clear = true }),
        callback = function(ev)
          vim.lsp.start(vim.tbl_deep_extend("keep", opts.lsp or {}, {
            name = 'moonbit-lsp',
            cmd = { 'moonbit-lsp' },
            root_dir = vim.fs.root(ev.buf, { 'moon.mod.json' }),
          }))
        end
      })
    end
  end
}
