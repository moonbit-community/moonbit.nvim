# Contributing

## Running Tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). Run them with:

```sh
make test
```

This will clone plenary into `.deps/` on first run, then execute all test files.

### Writing Tests

- Add test files under `tests/` with the `_spec.lua` suffix
- Tests use the busted syntax (`describe`, `it`, `assert`)
- Run a single test file interactively in Neovim with `:PlenaryBustedFile %`
