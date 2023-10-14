" Vim compiler file
" Compiler: Moon (distrbuted as moonbit)
" Maintainer: Haoxiang Fei <tonyfettes@tonyfettes.com>
" Last Change: 2023 Oct 15

if exists("current_compiler")
  finish
endif
let current_compiler = "moonbit"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=moon\ $*
CompilerSet errorformat=%E%f:%l:%c-%e:%k\ %m,%C\ %m,
      \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
