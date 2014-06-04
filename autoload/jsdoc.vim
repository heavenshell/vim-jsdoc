" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.0.5
" WebPage:  http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JsDoc to your JavaScript file.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:jsdoc_input_description')
  let g:jsdoc_input_description = 0
endif
" Prompt user for function description
if !exists('g:jsdoc_additional_descriptions')
  let g:jsdoc_additional_descriptions = 0
endif
" Prompt user for return type
if !exists('g:jsdoc_return')
  let g:jsdoc_return = 1
endif
" Prompt user for return description
if !exists('g:jsdoc_return_description')
  let g:jsdoc_return_description = 1
endif
" Allow prompt to input
if !exists('g:jsdoc_allow_input_prompt')
  let g:jsdoc_allow_input_prompt = 0
endif

function! jsdoc#insert()
  let l:jsDocregex = '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*[:=]\s*function\s*(\s*\([^)]*\)\s*).*$'
  let l:jsDocregex2 = '^.\{-}\s*function\s\+\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*).*$'

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
    let l:desc = input('Description: ')
  endif
  call add(l:lines, l:space. '/**')
  call add(l:lines, l:space . ' * ' . l:desc)
  call add(l:lines, l:space . ' *')
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
      if g:jsdoc_allow_input_prompt == 1
        let l:argType = input('Argument "' . l:arg . '" type: ')
        let l:argDescription = input('Argument "' . l:arg . '" description: ')
        " Prepend space to start of description only if it was provided
        if l:argDescription != ''
          let l:argDescription = ' ' . l:argDescription
        endif
        call add(l:lines, l:space . ' * @param {' . l:argType . '} ' . l:arg . l:argDescription)
      else
        call add(l:lines, l:space . ' * @param ' . l:arg)
      endif
    endfor
  endif
  if g:jsdoc_return == 1
    if g:jsdoc_allow_input_prompt == 1
      let l:returnType = input('Return type (blank for no @return): ')
      let l:returnDescription = ''
      if l:returnType != ''
        if g:jsdoc_return_description == 1
          let l:returnDescription = input('Return description: ')
        endif
        if l:returnDescription != ''
          let l:returnDescription = ' ' . l:returnDescription
        endif
        call add(l:lines, l:space . ' * @return {' . l:returnType . '}' . l:returnDescription)
      else
        call add(l:lines, l:space . ' * @return {undefined}')
      endif
    else
      call add(l:lines, l:space . ' * @return {undefined}')
    endif
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
