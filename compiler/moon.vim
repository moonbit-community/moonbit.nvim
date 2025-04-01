" Vim compiler file
" Compiler: Moon (distrbuted with MoonBit)
" Maintainer: Haoxiang Fei <tonyfettes@tonyfettes.com>
" Last Change: 2023 Nov 20

if exists("current_compiler")
  finish
endif
let current_compiler = "moon"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=moon\ $*
CompilerSet errorformat=%EError:\ [%n],
      \%WWarning:\ [%n],
      \%W%f:%l:%c-%e:%k\ [E%n]\ Warning:\ %m,
      \%E%f:%l:%c-%e:%k\ [E%n]\ %m,
      \%-C%.%#╭─[%f:%l:%c],
      \%C%.%#│%.%#╰─%#\ %m,
      \%-C%.%#│%.%#,
      \%-C─%#╯

let &cpo = s:cpo_save
unlet s:cpo_save
