" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.11.1
" WebPage:  http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JSDoc to your JavaScript file.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

let g:jsdoc_input_description       = get(g:, 'jsdoc_input_description')
let g:jsdoc_additional_descriptions = get(g:, 'jsdoc_additional_descriptions')
let g:jsdoc_return                  = get(g:, 'jsdoc_return', 1)
let g:jsdoc_return_description      = get(g:, 'jsdoc_return_description', 1)
let g:jsdoc_allow_input_prompt      = get(g:, 'jsdoc_allow_input_prompt')
let g:jsdoc_access_descriptions     = get(g:, 'jsdoc_access_descriptions')
let g:jsdoc_underscore_private      = get(g:, 'jsdoc_underscore_private')
let g:jsdoc_allow_shorthand         = get(g:, 'jsdoc_allow_shorthand')
let g:jsdoc_enable_es6              = get(g:, 'jsdoc_enable_es6')
let g:jsdoc_custom_args_regex_only  = get(g:, 'jsdoc_custom_args_regex_only')

let g:jsdoc_param_description_separator =
      \ get(g:, 'jsdoc_param_description_separator', ' ')
let g:jsdoc_custom_args_hook = exists('g:jsdoc_custom_args_hook')
      \ ? g:jsdoc_custom_args_hook
      \ : {}
let g:jsdoc_type_hook = exists('g:jsdoc_type_hook')
      \ ? g:jsdoc_type_hook
      \ : {}

let g:jsdoc_user_defined_tags = exists('g:jsdoc_user_defined_tags')
      \ ? g:jsdoc_user_defined_tags
      \ : {}

" Default tag names
"   @returns      (synonyms: @return)
"   @function     (synonyms: @func, @method)
"   @param        (synonyms: @arg, @argument)
"   @description  (synonyms: @desc)
"   @class        (synonyms: @constructor)
let s:jsdoc_default_tags = {
      \   'returns':   'returns',
      \   'function':  'function',
      \   'param':     'param',
      \   'class':     'class'
      \ }

" This is the value that's actually used
let g:jsdoc_tags = exists('g:jsdoc_tags')
      \ ? g:jsdoc_tags
      \ : {}

" Fill in any missing ones with defaults, keeping user overrides
call extend(g:jsdoc_tags, s:jsdoc_default_tags, 'keep')

" Add param types when `g:jsdoc_input_description=1` and has typed parameter,
" such as TypeScript.
let s:candidate_type = ''

" Return data types for argument type auto completion :)
function! jsdoc#listDataTypes(A, L, P) abort
  let l:types = [
      \ 'null', 'undefined',
      \ 'boolean', 'Boolean',
      \ 'number', 'Number',
      \ 'string', 'String',
      \ 'symbol', 'Symbol',
      \ 'object', 'Object',
      \ 'function', 'Function',
      \ 'array', 'Array',
      \ 'regexp', 'RegExp',
      \ 'date', 'Date',
      \ 'error', 'Error',
      \ 'map', 'Map',
      \ 'promise', 'Promise',
      \ 'proxy', 'Proxy',
      \ 'set', 'Set',
      \ 'typedArray', 'TypedArray',
      \ 'weakmap', 'WeakMap',
      \ 'weakset', 'WeakSet']

  if s:candidate_type != ''
    " Ignore Builtin types. Already defined at `l:types`.
    if index(l:types, s:candidate_type) == -1
      call insert(l:types, s:candidate_type, 0)
    endif
  endif
  return join(l:types, "\n")
endfunction

if g:jsdoc_allow_shorthand == 1
  echohl Error | echomsg 'g:jsdoc_allow_shorthand is deprecated. Use g:jsdoc_enable_es6 instead.' | echohl None
endif

" FIXME
" regex['arrow'] extracted extra chars.
" If `const foo = (arg1, arg2) => true;` extracts `(arg`, `arg2)`.
" We don't need `(` and `)`.
" Currently `(` and `)` are deleted by substitute().
" @see jsdoc#insert() for where these regexes are matched to the string
let s:regexs = {
      \   'function_declaration':  '^.\{-}\s*function\s*\*\?\s\+\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*\**(\s*\([^)]*\)\s*).*$',
      \   'function_expression':   '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*[:=]\s*function\s*\**\s*(\s*\([^)]*\)\s*).*$',
      \   'anonymous_function':    '^.\{-}\s*function\s*\**\s*(\s*\([^)]*\)\s*).*$',
      \   'class_extend':          '^.\{-}\s*class\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)*\s*extends\s*\(\([^{]*\)\).*$',
      \   'class':                 '^.\{-}\s*class\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\).*$',
      \   'shorthand':             '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*).*$',
      \   'static':                '^.\{-}\s*static\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*).*$',
      \   'arrow':                 '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*[:=]\s*(\s*\([^)]*\)\s*)\s*=>.*$',
      \   'arrow_single':          '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*[:=]\s*\([^=]*\).*$',
      \   'return_type':           ')\(:\|:\s\|\s*:\s*\)\([a-zA-Z]\+\).*$',
      \   'interface':             '^.\{-}\s*interface\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\).*$',
      \   'access':                '^\s*\(public\|protected\|private\)',
      \   'implements':            '^.\{-}\s*implements\s*\(\([^{]*\)\).*$',
      \   'extends':               '^.\{-}\s*extends\s*\([^\s*]\)'
      \ }

function! s:trim(value)
  return substitute(a:value, '\s', '', 'g')
endfunction

" If someday Vim support lambda use lambda.
function! s:parse_type(args)
  let results = []
  for arg in a:args
    if arg =~# ':'
      let args = split(arg, ':')
      let val = s:trim(args[0])
      if val =~# s:regexs['access']
        let val = s:trim(split(val, s:regexs['access'])[0])
      endif

      let type = s:trim(args[1])
      " Split keywaord args.
      if type =~# '='
        let type = s:trim(split(type, '=')[0])
      endif
      call add(results, {'val': val, 'type': type})
    else
      call add(results, {'val': s:trim(arg), 'type': ''})
    endif
  endfor

  return results
endfunction

function! s:build_description(argType, arg) abort
  let l:description = ''
  let l:override = 0
  if has_key(g:jsdoc_type_hook, a:argType)
    if type(g:jsdoc_type_hook[a:argType]) == 1
      let l:description = g:jsdoc_type_hook[a:argType]
    elseif type(g:jsdoc_type_hook[a:argType]) == 4
      if has_key(g:jsdoc_type_hook[a:argType], 'force_override')
        let l:override = g:jsdoc_type_hook[a:argType]['force_override']
      endif
      if has_key(g:jsdoc_type_hook[a:argType], 'description')
        let l:description = g:jsdoc_type_hook[a:argType]['description']
      endif
    endif
  endif

  " Prompt for description
  if l:override == 0
    let l:inputDescription = input('Argument "' . a:arg['val'] . '" description: ')
    if l:inputDescription !=# ''
      let l:description = l:inputDescription
    endif
  endif

  return l:description
endfunction

function! s:hookArgs(lines, space, arg, hook, argType, argDescription) abort
  " Hook function signature's args for insert as default value.
  if g:jsdoc_custom_args_hook == {}
    call add(a:lines, a:space . ' * @' . g:jsdoc_tags['param'] . ' ' . a:arg)
  else

    let l:matchedArg = ''

    if g:jsdoc_custom_args_regex_only == 1
      " Loop through regexes list `hook = keys(g:jsdoc_custom_args_hook)` to
      " find first instance where the arg name is matched by the hook regex
      for l:pat in a:hook
        if !empty(matchstr(a:arg, l:pat))
          let l:matchedArg = l:pat
          break
        endif
      endfor
    else
      let l:matchedArg = matchstr(a:hook, a:arg)
    endif

    if l:matchedArg ==# ''

      let l:type = '{' . a:argType . '} '
      let l:description = a:argDescription !=# ''
            \ ? g:jsdoc_param_description_separator . a:argDescription
            \ : ''
      call add(a:lines, a:space . ' * @' . g:jsdoc_tags['param'] . ' ' . l:type . a:arg . l:description)

    else

      let l:type = ''
      let l:customArg = g:jsdoc_custom_args_hook[l:matchedArg]
      if a:argType ==# ''
        if has_key(l:customArg, 'type')
          let l:type = l:customArg['type'] . ' '
        endif
      else
        let l:type = '{' . a:argType . '} '
      endif

      let l:description = ''
      if a:argDescription ==# ''
        if has_key(l:customArg, 'description')
          let l:description = g:jsdoc_param_description_separator . l:customArg['description']
        endif
      else
        let l:description = g:jsdoc_param_description_separator . a:argDescription
      endif
      call add(a:lines, a:space . ' * @' . g:jsdoc_tags['param'] . ' ' . l:type . a:arg . l:description)

    endif

  endif

  return a:lines

endfunction

function! s:determine_style(line)
  let l:is_class     = 0
  let l:is_function  = 0
  let l:is_named     = 0
  let l:is_static    = 0
  let l:is_interface = 0
  let l:regex        = 0

  if a:line =~ s:regexs['function_declaration']
    let l:is_function = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['function_declaration']
  elseif a:line =~ s:regexs['function_expression']
    let l:is_function = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['function_expression']
  elseif a:line =~ s:regexs['anonymous_function']
    let l:is_function = 1
    let l:regex       = s:regexs['anonymous_function']
  elseif g:jsdoc_enable_es6 == 1 && a:line =~ s:regexs['static']
    let l:is_function = 1
    let l:is_named    = 1
    let l:is_static   = 1
    let l:regex       = s:regexs['static']
  elseif (g:jsdoc_allow_shorthand == 1 || g:jsdoc_enable_es6 == 1) && a:line =~ s:regexs['shorthand']
    let l:is_function = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['shorthand']
  elseif g:jsdoc_enable_es6 == 1 && a:line =~ s:regexs['arrow']
    let l:is_function = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['arrow']
  elseif g:jsdoc_enable_es6 == 1 && a:line =~ s:regexs['arrow_single']
    let l:is_function = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['arrow_single']
  elseif g:jsdoc_enable_es6 == 1 &&  a:line =~ s:regexs['class_extend']
    let l:is_class    = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['class_extend']
  elseif g:jsdoc_enable_es6 == 1 && a:line =~ s:regexs['class']
    let l:is_class    = 1
    let l:is_named    = 1
    let l:regex       = s:regexs['class']
  elseif a:line =~ s:regexs['interface']
    let l:is_interface = 1
    let l:is_named     = 1
    let l:regex        = s:regexs['interface']
  endif

  return {
        \ 'is_class':     l:is_class,
        \ 'is_function':  l:is_function,
        \ 'is_named':     l:is_named,
        \ 'is_static':    l:is_static,
        \ 'is_interface': l:is_interface,
        \ 'regex':        l:regex,
        \ }
endfunction

" Extract return type such as TypeScript.
function! s:extract_return_type(line)
  let l:return_type = ''
  if a:line =~ s:regexs['return_type']
    let matched = matchstr(a:line, s:regexs['return_type'], 0)
    if matched != ''
      " FIXME:
      " If signature has union tyoe, such as `function foo(): string | number {`
      " Regex `\([a-zA-Z]\+\).*$` would extract like `number | string {`.
      " So delete `{` if exists.
      let l:return_type = matchstr(matched, '\([a-zA-Z]\+\).*$', 0)
      let l:return_type = substitute(l:return_type, '\(\s*{\|{\)', '', 'g')
    endif
  endif

  return l:return_type
endfunction

function! jsdoc#insert() abort
  let l:line = getline('.')
  let l:indentCharSpace = ' '
  let l:indentCharTab   = '	'
  let l:autoexpandtab   = &l:expandtab

  if l:autoexpandtab == 0 " noexpandtab
    " tabs
    let l:indent      = indent('.') / &l:tabstop
    let l:indentChar  = l:indentCharTab
  elseif l:autoexpandtab == 1 " expandtab
    " spaces
    let l:indent      = indent('.')
    let l:indentChar  = l:indentCharSpace
  endif

  let l:space = repeat(l:indentChar, l:indent)

  " Determine function defintion style
  let l:style        = s:determine_style(l:line)
  let l:is_class     = l:style['is_class']
  let l:is_function  = l:style['is_function']
  let l:is_named     = l:style['is_named']
  let l:is_static    = l:style['is_static']
  let l:is_interface = l:style['is_interface']
  let l:regex        = l:style['regex']

  let l:lines = []
  let l:desc = g:jsdoc_input_description == 1 ? input('Description: ') : ''
  call add(l:lines, l:space . '/**')
  call add(l:lines, l:space . ' * ' . l:desc)
  " Class and interface generate only typed name.
  if !l:is_class && !l:is_interface
    call add(l:lines, l:space . ' *')
  endif

  let l:funcName = ''
  let l:parent_class = ''
  let l:implements = ''
  let l:return_type = ''
  if l:is_function || l:is_class || l:is_interface

    " Parse function definition
    " @FIXME: Does not work if function is split over several lines...
    " e.g.
    " ```
    " function name(
    "   arg1
    "   arg2
    " ) { }
    let l:argString = ''
    if l:is_named
      let l:funcName = substitute(l:line, l:regex, '\1', 'g')
      let l:argString = substitute(l:line, l:regex, '\2', 'g')
    else
      let l:argString = substitute(l:line, l:regex, '\1', 'g')
    endif
    let l:args = []
    if l:is_class
      "let l:parent_class = substitute(l:argString, '\s', '', '')
      if l:argString =~ s:regexs['implements']
        let implements = s:trim(substitute(l:argString, s:regexs['implements'], '\1', 'g'))
      endif
      let l:extends = substitute(l:argString, s:regexs['extends'], '\1', 'g')
      let l:parent_class = matchstr(l:extends, '^\([a-zA-Z0-9-_$]*\)')
    else
      let l:args = split(l:argString, '\s*,\s*')
    endif

    " Return type for typed language such as TypeScript.
    let l:return_type = s:extract_return_type(l:line)

    " Parse typed args. ex: TypeScript's argument.
    let l:args = s:parse_type(l:args)

    if g:jsdoc_additional_descriptions == 1
      call add(l:lines, l:space . ' * @name ' . l:funcName)
      call add(l:lines, l:space . ' * @' . g:jsdoc_tags['function'])
    endif

    if g:jsdoc_access_descriptions > 0
      " either @access public/private
      " or     @public/private
      let l:access_tag = g:jsdoc_access_descriptions == 1
            \ ? ' * @access '
            \ : ' * @'
      if l:line =~ s:regexs['access']
        let l:access = s:trim(matchstr(l:line, s:regexs['access']))
      else

        let l:access = g:jsdoc_underscore_private == 1 && l:funcName[0] ==# '_'
              \ ? 'private'
              \ : 'public'
      endif

      call add(l:lines, l:space . l:access_tag . l:access)
    endif

    if l:is_static > 0
      call add(l:lines, l:space . ' * @static')
    endif

    " Add user defined tags.
    for t in keys(g:jsdoc_user_defined_tags)
      call add(l:lines, l:space . ' * ' . t . ' ' . g:jsdoc_user_defined_tags[t])
    endfor

    let l:hook = keys(g:jsdoc_custom_args_hook)
    for l:arg in l:args
      let s:candidate_type = ''
      if g:jsdoc_enable_es6 == 1
        " Remove `(` or `)` from args.
        let l:arg['val'] = substitute(l:arg['val'], '\((\|)\)', '', '')
      endif

      if g:jsdoc_allow_input_prompt == 1
        if l:arg['type'] != ''
          let s:candidate_type = l:arg['type']
        endif
        let l:argType = input('Argument "' . l:arg['val'] . '" type: ', '', 'custom,jsdoc#listDataTypes')
        redraw | echo ''
        let l:argDescription = s:build_description(l:argType, l:arg)
        if g:jsdoc_custom_args_hook == {}
          " Prepend separator to start of description only if it was provided
          if l:argDescription !=# ''
            let l:argDescription = g:jsdoc_param_description_separator . l:argDescription
          endif
          call add(l:lines, l:space . ' * @' . g:jsdoc_tags['param'] . ' {' . l:argType . '} ' . l:arg['val'] . l:argDescription)
        else
          let l:lines = s:hookArgs(l:lines, l:space, l:arg['val'], l:hook, l:argType, l:argDescription)
        endif
      else
        " Hook args.
        let l:lines = s:hookArgs(l:lines, l:space, l:arg['val'], l:hook, l:arg['type'], '')
      endif
    endfor
  endif

  if l:is_class || l:is_interface
    " Class and inteface does not need return description.
    if l:parent_class != ''
      call add(l:lines, l:space . ' *')
      if l:implements != ''
        call add(l:lines, l:space . ' * @implements ' . '{' . l:implements . '}')
      endif

      call add(l:lines, l:space . ' * @extends ' . '{' . l:parent_class . '}')
    endif
  elseif g:jsdoc_return == 1
    if g:jsdoc_allow_input_prompt == 1
      let s:candidate_type = l:return_type
      let l:returnType = input('Return type (blank for no @' . g:jsdoc_tags['returns'] . '): ', '', 'custom,jsdoc#listDataTypes')
      redraw | echo ''
      let l:returnDescription = ''
      if l:returnType !=# ''
        if g:jsdoc_return_description == 1
          let l:returnDescription = input('Return description: ')
        endif
        if l:returnDescription !=# ''
          let l:returnDescription = ' ' . l:returnDescription
        endif
        call add(l:lines, l:space . ' * @' . g:jsdoc_tags['returns'] . ' {' . l:returnType . '}' . l:returnDescription)
      endif
    else
      let l:return_type = l:return_type == ''
            \ ? ' {undefined}'
            \ : printf(' {%s}', l:return_type)

      cal add(l:lines, l:space . ' * @' . g:jsdoc_tags['returns'] . l:return_type)
    endif
  endif
  call add(l:lines, l:space . ' */')

  let l:paste = &g:paste
  let &g:paste = 1

  call append(line('.') - 1, l:lines)

  let l:pos = line('.') - (len(l:lines) - 1)

  silent! execute 'normal! ' . l:pos . 'G$'
  if l:desc ==# '' && l:funcName !=# ''
    silent! execute 'normal! a' . l:funcName
  endif

  let &g:paste = l:paste
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
