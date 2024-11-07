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
    treesitter =  { enabled = true },
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

`moonbit.nvim` provides a [neotest](https://github.com/nvim-neotest/neotest) adapter, example config using `lazy.nvim`

```lua
{
  "nvim-neotest/neotest",
  depedencies = {
    "moonbit-community/moonbit.nvim",
  },
  -- Using opts instead of config maximizes composability of overrides.
  -- See: https://github.com/folke/lazy.nvim/discussions/1185#discussioncomment-7579598
  opts = function(_, opts)
    if not opts.adapters then opts.adapters = {} end
    table.insert(opts.adapters, require("neotest-moonbit"))
  end,
}
```
