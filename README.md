# moonbit.nvim

Neovim support for the [MoonBit language](https://www.moonbitlang.com).

## Roadmap

- [ ] Tree-sitter support:
  - [x] Highlights
  - [ ] Folds
  - [ ] Indents
- Build system support:
  - [x] Compiler plugin
  - [x] Diagnostics through [nvim-lint](https://github.com/mfussenegger/nvim-lint)

## Installation

First you need to have the MoonBit toolchain installed. You can follow the
instruction on the [Download Page](https://www.moonbitlang.com/download/) of
the MoonBit language.

If you're on Arch Linux, you can use the
[moonbit-bin](https://aur.archlinux.org/packages/moonbit-bin) package from AUR.

### `lazy.nvim`

```lua
{
  'tonyfettes/moonbit.nvim',
  ft = { 'moonbit' }
  dependencies = {
    'mfussenegger/nvim-lint', -- for linting support
  },
  opts = {},
}
```
