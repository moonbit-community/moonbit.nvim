" Vim filetype plugin file
" Language:	MoonBit
" Maintainer:	Tony Fettes (https://github.com/tonyfettes/moonbit.nvim)
" Last Change:	2023 Dec 9

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

setlocal formatoptions-=t formatoptions+=ro
setlocal comments=:///,://
setlocal commentstring=//%s

let b:undo_ftplugin = 'setlocal formatoptions< comments< commentstring<'

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: sw=2 sts=2 et
