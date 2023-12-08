" Vim filetype plugin file
" Language:	MoonBit
" Maintainer:	Tony Fettes (https://github.com/tonyfettes/moonbit.nvim)
" Last Change:	2023 Dec 9

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal comments=:///,://
setlocal commentstring=//%s

let b:undo_ftplugin = 'setl com< cms<'

" vim: sw=2 sts=2 et
