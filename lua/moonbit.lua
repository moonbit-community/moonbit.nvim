return {
  setup = function (opts) {
    -- detect filetype
    vim.filetype.add {
      extension = {
        mbt = 'moonbit'
      },
      filename = {
        ['moon.pkg'] = 'moonpkg',
        ['moon.mod'] = 'moonmod'
      },
    }
  }
}
