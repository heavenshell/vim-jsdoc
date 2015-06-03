" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.1.0
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
" Set @return tag plurality
if !exists('g:jsdoc_return_plural')
  let g:jsdoc_return_plural = 0
endif
" Prompt user for return description
if !exists('g:jsdoc_return_description')
  let g:jsdoc_return_description = 1
endif
" Allow prompt to input
if !exists('g:jsdoc_allow_input_prompt')
  let g:jsdoc_allow_input_prompt = 0
endif
" Access tag (default 0)
" http://usejsdoc.org/tags-access.html
if !exists('g:jsdoc_access_descriptions')
  let g:jsdoc_access_descriptions = 0
endif
" Use underscore starting functions as private convention (default 0)
" http://usejsdoc.org/tags-access.html
" used only if g:jsdoc_access_descriptions > 0
if !exists('g:jsdoc_underscore_private')
  let g:jsdoc_underscore_private = 0
endif
" Enable to use ECMAScript6 shorthand method syntax.
" /**
"  * foo
"  *
"  * @param foo
"  */
" foo(data) {
" }
if !exists('g:jsdoc_allow_shorthand')
  let g:jsdoc_allow_shorthand = 0
endif
" Use seperator between @param name and description.
if !exists('g:jsdoc_param_description_seperator')
	let g:jsdoc_param_description_seperator = " "
endif

" Return data types for argument type auto completion :)
function! jsdoc#listDataTypes(A,L,P)
  let l:types = ['boolean', 'null', 'undefined', 'number', 'string', 'symbol', 'object']
  return join(l:types, "\n")
endfunction

function! jsdoc#insert()
  let l:jsDocregex = '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*[:=]\s*function\s*\**(\s*\([^)]*\)\s*).*$'
  let l:jsDocregex2 = '^.\{-}\s*function\s\+\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*\**(\s*\([^)]*\)\s*).*$'
  " ECMAScript6 shorthand syntax.
  let l:jsDocregex3 = '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*).*$'

  let l:line = getline('.')
  let l:indentCharSpace = ' '
  let l:indentCharTab = '	'
  let l:autoexpandtab = &l:expandtab

  if l:autoexpandtab == 0 " noexpandtab
    " tabs
    let l:indent = indent('.') / &l:tabstop
    let l:indentChar = l:indentCharTab
  elseif l:autoexpandtab == 1 " expandtab
    " spaces
    let l:indent = indent('.')
    let l:indentChar = l:indentCharSpace
  endif

  let l:space = repeat(l:indentChar, l:indent)

  if l:line =~ l:jsDocregex
    let l:flag = 1
    let l:regex = l:jsDocregex
  elseif l:line =~ l:jsDocregex2
    let l:flag = 1
    let l:regex = l:jsDocregex2
  elseif g:jsdoc_allow_shorthand == 1 && l:line =~ l:jsDocregex3
    let l:flag = 1
    let l:regex = l:jsDocregex3
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

    if g:jsdoc_access_descriptions > 0
      let l:access = 'public'

      if g:jsdoc_underscore_private == 1
        let l:funcNameFirstChar = l:funcName[0]

        if l:funcNameFirstChar == '_'
          let l:access = 'private'
        endif
      endif

     if g:jsdoc_access_descriptions == 1
       " use: http://usejsdoc.org/tags-access.html
       let l:access_tag = ' * @access '
     else
       " use other form, e.g.: http://usejsdoc.org/tags-public.html
       let l:access_tag = ' * @'
     endif

      call add(l:lines, l:space . l:access_tag . l:access)

    endif

    for l:arg in l:args
      if g:jsdoc_allow_input_prompt == 1
        let l:argType = input('Argument "' . l:arg . '" type: ', '', 'custom,jsdoc#listDataTypes')
        let l:argDescription = input('Argument "' . l:arg . '" description: ')
        " Prepend seperator to start of description only if it was provided
        if l:argDescription != ''
          let l:argDescription = g:jsdoc_param_description_seperator . l:argDescription
        endif
        call add(l:lines, l:space . ' * @param {' . l:argType . '} ' . l:arg . l:argDescription)
      else
        call add(l:lines, l:space . ' * @param ' . l:arg)
      endif
    endfor
  endif
  if g:jsdoc_return == 1
    let l:returnTag = '@return'
    if g:jsdoc_return_plural == 1
      let l:returnTag = l:returnTag . 's'
    endif
    if g:jsdoc_allow_input_prompt == 1
      let l:returnType = input('Return type (blank for no ' . l:returnTag . '): ', '', 'custom,jsdoc#listDataTypes')
      let l:returnDescription = ''
      if l:returnType != ''
        if g:jsdoc_return_description == 1
          let l:returnDescription = input('Return description: ')
        endif
        if l:returnDescription != ''
          let l:returnDescription = ' ' . l:returnDescription
        endif
        call add(l:lines, l:space . ' * ' . l:returnTag . ' {' . l:returnType . '}' . l:returnDescription)
      endif
    else
      call add(l:lines, l:space . ' * ' . l:returnTag . ' {undefined}')
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
