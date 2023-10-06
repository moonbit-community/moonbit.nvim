" Language: Moonbit
" Maintainer: Haoxiang Fei (https://github.com/tonyfettes/moonbit.nvim)
" Last Change: 2023 Oct 6

if exists('b:did_ftplugin')
  finish
endif

let b:did_ftplugin = 1

setlocal formatoptions-=t

setlocal comments=://
setlocal commentstring=//%s

" vim: sw=2 sts=2 et
