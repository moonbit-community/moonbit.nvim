return {
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local has_treesitter, parsers = pcall(require, 'nvim-treesitter.parsers')
    local enable = treesitter_opts.enable or true
    if has_treesitter and enable then
      require 'moonbit.treesitter'.setup(treesitter_opts)
    end

    local has_lint, lint = pcall(require, 'lint')
    if has_lint then
      lint.linters.moon = {
        cmd = 'moon',
        stdin = false,
        append_fname = false,
        stream = 'stderr',
        ignore_exitcode = true,
        args = { 'check', '-q', '--no-render', },
        parser = require 'lint.parser'.from_errorformat [[%W%f:%l:%c-%e:%k\ Warning\ %n:\ %m,%E%f:%l:%c-%e:%k\ %m,%C%m,%-G%.%#]]
      }
      lint.linters_by_ft = {
        moonbit = { 'moon' }
      }
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require 'lint'.try_lint()
        end,
      })
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
