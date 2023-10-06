let s:cpo_save = &cpo
set cpo&vim

au BufRead,BufNewFile *.mbt setfiletype moonbit
au BufRead,BufNewFile moon.pkg setfiletype moonpkg
au BufRead,BufNewFile moon.mod setfiletype moonmod

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
