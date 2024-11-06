# moonbit.nvim

**NOTICE: The parser file (`parser.mly`) in the [moonbit-docs](https://github.com/moonbitlang/moonbit-docs) has not been updated for more than 3 months. Please use their setups for writing up-to-date MoonBit programs.**

Neovim support for the [MoonBit language](https://www.moonbitlang.com).

![Screenshot from 2023-11-21 01-24-56](https://github.com/tonyfettes/moonbit.nvim/assets/29998228/0e3080e4-63c4-4f72-8ec7-fcf8bb82181c)

## Roadmap

- [ ] Tree-sitter support
  - [x] Highlights
  - [x] Folds
  - [ ] Indents
- [ ] Build system support
  - [x] Compiler plugin
  - [x] ~Diagnostics through [nvim-lint](https://github.com/mfussenegger/nvim-lint)~ Removed b/c LSP
- [ ] JSON Schema
- [x] Language server

## Installation

First you need to have the MoonBit toolchain installed. You can follow the
instruction on the [Download Page](https://www.moonbitlang.com/download/) of
the MoonBit language.

### `lazy.nvim`

```lua
{
  'tonyfettes/moonbit.nvim',
  ft = { 'moonbit' },
  opts = {
    -- optionally disable the treesitter integration
    treesitter =  { enabled = true }
    -- configure the language server integration
    -- set `lsp = false` to disable the language server integration
    lsp = {
      -- provide an `on_attach` function to run when the language server starts
      on_attach = function(client, bufnr) end
      -- provide client capabilities to pass to the language server
      capabilities = vim.lsp.protocol.make_client_capabilities(),
    }
  },
}
```
## neotest

`moonbit.nvim` provides a [neotest](https://github.com/nvim-neotest/neotest) adapter, example config using `lazy.nvim`

```lua
{
  "nvim-neotest/neotest",
  depedencies = {
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
