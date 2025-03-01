# moonbit.nvim

Neovim support for the [MoonBit language](https://www.moonbitlang.com).

![Screenshot from 2023-11-21 01-24-56](https://github.com/tonyfettes/moonbit.nvim/assets/29998228/0e3080e4-63c4-4f72-8ec7-fcf8bb82181c)

## Roadmap

- [x] Tree-sitter support
  - [x] Highlights
  - [x] Folds
  - [x] Indents ([#9](https://github.com/moonbit-community/moonbit.nvim/pull/9))
- [x] Build system support
  - [x] Compiler plugin
  - [x] ~Diagnostics through [nvim-lint](https://github.com/mfussenegger/nvim-lint)~ Removed b/c LSP
- [ ] JSON Schema
- [x] Language server
- [x] Neotest support ([#10](https://github.com/moonbit-community/moonbit.nvim/pull/10))

## Installation

First you need to have the MoonBit toolchain installed. You can follow the
instruction on the [Download Page](https://www.moonbitlang.com/download/) of
the MoonBit language.

### `lazy.nvim`

```lua
{
  'moonbit-community/moonbit.nvim',
  ft = { 'moonbit' },
  opts = {
    -- optionally disable the treesitter integration
    treesitter =  {
      enabled = true,
      -- Set false to disable automatic installation and updating of parsers.
      auto_install = true
    },
    -- configure the language server integration
    -- set `lsp = false` to disable the language server integration
    lsp = {
      -- provide an `on_attach` function to run when the language server starts
      on_attach = function(client, bufnr) end,
      -- provide client capabilities to pass to the language server
      capabilities = vim.lsp.protocol.make_client_capabilities(),
    }
  },
}
```
## neotest

`moonbit.nvim` provides a [neotest](https://github.com/nvim-neotest/neotest) adapter. Below is an minimal example config using `lazy.nvim`:

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "moonbit-community/moonbit.nvim",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-moonbit"),
      },
    })
  end,
}
```

According to the [lazy.nvim docs](https://lazy.folke.io/usage/structuring#%EF%B8%8F-importing-specs-config--opts), setting the `config` property in an override spec might accidentally overwrite that of an existing parent spec. On the other hand, the `opts` property is guaranteed to be merged with that of the parent spec. Therefore, we recommend the following settings:

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "moonbit-community/moonbit.nvim",
  },
  opts = function(_, opts)
    if not opts.adapters then opts.adapters = {} end
    table.insert(opts.adapters, require("neotest-moonbit"))
  end,
}
```
