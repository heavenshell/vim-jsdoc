" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.0.1
" WebPage:  http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JsDoc to your JavaScript file.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:jsdoc_input_description')
  let g:jsdoc_input_description = 0
endif
" TODO Think about additional params...
if !exists('g:jsdoc_additional_descriptions')
  let g:jsdoc_additional_descriptions = 0
endif

function! jsdoc#insert()
  let l:jsDocregex = '\s*\([a-zA-Z]*\)\s*[:=]\s*function\s*(\s*\(.*\)\s*).*'
  let l:jsDocregex2 = '\s*function \([a-zA-Z]*\)\s*(\s*\(.*\)\s*).*'

  let l:line = getline('.')
  let l:indent = indent('.')
  let l:space = repeat(' ', l:indent)

  if l:line =~ l:jsDocregex
    let l:flag = 1
    let l:regex = l:jsDocregex
  elseif l:line =~ l:jsDocregex2
    let l:flag = 1
    let l:regex = l:jsDocregex2
  else
    let l:flag = 0
  endif

  let l:lines = []
  let l:desc = ''
  if g:jsdoc_input_description == 1
    let l:desc = input('Description :')
  endif
  call add(l:lines, l:space. '/**')
  call add(l:lines, l:space . ' * ' . l:desc)
  let l:funcName = ''
  if l:flag
    let l:funcName = substitute(l:line, l:regex, '\1', "g")
    let l:arg = substitute(l:line, l:regex, '\2', "g")
    let l:args = split(l:arg, '\s*,\s*')

    if g:jsdoc_additional_descriptions == 1
      call add(l:lines, l:space . ' * @name ' . l:funcName)
      call add(l:lines, l:space . ' * @function')
    endif

    for l:arg in l:args
      call add(l:lines, l:space . ' * @param ' . l:arg)
    endfor
  endif
  call add(l:lines, l:space . ' */')

  let l:paste = &g:paste
  let &g:paste = 1

  call append(line('.') - 1, l:lines)

  let l:pos = line('.') - (len(l:lines) - 1)

  silent! execute 'normal! ' . l:pos . 'G$'
  if l:desc == '' && l:funcName != ''
  silent! execute 'normal! a' . l:funcName
  endif

  let &g:paste = paste
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
