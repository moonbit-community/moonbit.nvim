local editor = require 'moonbit.editor'
local compiler = require 'moonbit.compiler'
local target = require 'moonbit.target'
local jsonls = require 'moonbit.jsonls'

local mooncakes = require 'moonbit.mooncakes'

return {
  api = {
    editor = editor,
  },
  setup = function(opts)
    local treesitter_opts = opts.treesitter or {}
    local treesitter_enabled = treesitter_opts.enabled or true
    if treesitter_enabled then
      require('moonbit.treesitter').setup(treesitter_opts)
    end

    -- add plenary filetype
    local has_plenary = pcall(require, "plenary")
    if has_plenary then
      require("plenary.filetype").add_file("moonbit")
    end

    local lsp = nil
    if opts.lsp ~= false then
      lsp = require('moonbit.lsp')
    end

    jsonls.setup(opts.jsonls)

    local function on_attach(ev)
      editor.on_attach(ev.buf)
      compiler.on_attach(ev.buf)
      if lsp ~= nil then
        lsp.on_attach(ev.buf, opts.lsp)
      end
    end

    local moonbit_augroup = vim.api.nvim_create_augroup('moonbit', { clear = true });

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'moonbit',
      group = moonbit_augroup,
      callback = on_attach,
    })
    vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
      pattern = { '*.mbt.md', 'moon.pkg', 'moon.pkg.json', 'moon.mod.json', },
      group = moonbit_augroup,
      callback = on_attach,
    })

    target.setup_moonbit_target()

    do
      local mc = opts.mooncakes or {}
      mooncakes.setup {
        use_local = mc.use_local ~= false,
        virtual_text = mc.virtual_text ~= false,
      }
    end
  end
}
