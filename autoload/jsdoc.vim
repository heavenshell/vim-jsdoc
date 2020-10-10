" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage:  http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JSDoc to your JavaScript, TypeScript file.
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

let g:jsdoc_templates_path = get(g:, 'jsdoc_templates_path', '')
let g:jsdoc_formatter = get(g:, 'jsdoc_formatter', 'jsdoc')
let g:jsdoc_lehre_path = get(
  \ g:,
  \ 'jsdoc_lehre_path',
  \ printf('%s/lib/lehre', expand('<sfile>:p:h:h'))
  \ )

let s:is_method_regex = '^.\{-}\s*\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*).*$'
let s:is_declarelation = '^.\{-}=\s*\(\([a-zA-Z_$][a-zA-Z0-9_$]*\)\s*(\s*\([^)]*\)\s*)\|(\s*\([^)]*\)\s*\).*$'
let s:registered_callback = ''
let s:results = []
let s:vim = {}

function! s:get_range() abort
  " Get visual mode selection.
  let mode = visualmode(1)
  if mode == 'v' || mode == 'V' || mode == ''
    let start_lineno = line("'<")
    let end_lineno = line("'>")
    return {'start_lineno': start_lineno, 'end_lineno': end_lineno}
  endif
  let current = line('.')
  return {'start_lineno': 0, 'end_lineno': '$'}
endfunction

function! s:create_cmd(style) abort
  let path = expand(g:jsdoc_lehre_path)
  if !executable(path)
    redraw
    echohl Error
    echo '`lehre` not found. Install `lehre`.'
    echohl None
    return
  endif

  let cmd = printf(
    \ '%s --style=%s --formatter=%s --stdin --nest --parser=ts',
    \ path,
    \ a:style,
    \ g:jsdoc_formatter,
    \ )
  if g:jsdoc_templates_path !=# ''
    let cmd = printf('%s --template-path=%s', cmd, expand(g:jsdoc_templates_path))
  endif

  return cmd
endfunction

function! s:insert_doc(docs, end_lineno) abort
  let paste = &g:paste
  let &g:paste = 1

  " Move to insert position
  silent! execute 'normal! ' . a:end_lineno . 'G$'
  " Insert doc
  silent! execute 'normal! O' . a:docs['doc']

  let &g:paste = paste
  silent! execute 'normal! ' . a:end_lineno . 'G$'
endfunction

function! s:callback(msg, start_lineno, is_method) abort
  let docs = reverse(json_decode(a:msg))
  let i = 0
  let length = len(docs)
  for d in docs
    " If generate methods's signature, jsdoc.vim would add dummy Class
    " signature. So ignore it.
    if i == 0 && a:is_method
      call s:insert_doc(d, a:start_lineno)
      break
    endif

    let start = a:start_lineno + d['start']['line']
    call s:insert_doc(d, start)
  endfor
endfunction

function! s:format_callback(msg, start_lineno, is_method) abort
  call add(s:results, a:msg)
endfunction

function! s:exit_callback(msg) abort
  if len(s:results)
    let view = winsaveview()
    silent execute '% delete'
    if has('nvim')
      " the -2 slicing is required to remove an extra new line
      call setline(1, s:results[0][:-2])
    else
      call setline(1, s:results)
    endif
    call winrestview(view)
  endif

  " Call usr registered callback
  if type(s:registered_callback) == 2
    let Callback = s:registered_callback
    call Callback(s:results)
  endif
  let s:results = []
endfunction

function! s:vim.execute(cmd, lines, start_lineno, is_method, cb, ex_cb) dict
  if has('nvim')
    if exists('s:job') && jobwait([s:job], 0)[0] == -1
      call jobstop(s:job)
    endif

    let s:job = jobstart(a:cmd, {
          \ 'on_stdout': {_, m -> a:cb(m, a:start_lineno, a:is_method)},
          \ 'on_exit': {_, m -> a:ex_cb(m)},
          \ 'stdout_buffered': 1,
          \ })

    call chansend(s:job, a:lines)
    call chanclose(s:job, 'stdin')
  elseif v:version >= 800 && !has('nvim')
    if exists('s:job') && job_status(s:job) != 'dead'
      call job_stop(s:job)
    endif

    let s:job = job_start(a:cmd, {
          \ 'callback': {_, m -> a:cb(m, a:start_lineno, a:is_method)},
          \ 'exit_cb': {_, m -> a:ex_cb(m)},
          \ 'in_mode': 'nl',
          \ })

    let channel = job_getchannel(s:job)
    if ch_status(channel) ==# 'open'
      call ch_sendraw(channel, a:lines)
      call ch_close_in(channel)
    endif
  endif
endfunction

function! jsdoc#register_callback(callback) abort
  let s:registered_callback = function(a:callback)
endfunction

function! jsdoc#insert(...) abort
  let range = s:get_range()
  let pos = getpos('.')
  let line = getline('.')

  silent! execute 'normal! 0'
  let is_not_range = range['start_lineno'] == 0 && range['end_lineno'] == '$'
  if is_not_range
    let start_lineno = line('.')
    let end_lineno = start_lineno
  else
    let start_lineno = range['start_lineno']
    let end_lineno = range['end_lineno']
  endif
  call setpos('.', pos)
  let cmd = s:create_cmd('json')

  let lines = join(getline(start_lineno, end_lineno), "\n")
  let is_method = 0
  if is_not_range
    let line = getline('.')
    let is_method = line =~ s:is_method_regex && line !~ 'function(.*)\|function [A-z0-9_]\+(.*)\|function [A-z0-9_]\+\s\+(.*)'
    if is_method && line !~ s:is_declarelation
      let lines = printf("%s\n%s", 'class ForJsDocDummyClass {', lines)
    endif
  endif
  let s:results = []

  call s:vim.execute(
    \ cmd,
    \ lines,
    \ start_lineno,
    \ is_method,
    \ function('s:callback'),
    \ function('s:exit_callback')
    \ )
endfunction

function! jsdoc#format(...) abort
  let lines = printf("%s\n", join(getbufline(bufnr('%'), 1, '$'), "\n"))
  let nest = 1
  let cmd = s:create_cmd('string')
  let end_lineno = line('.')
  let is_method = 0

  call s:vim.execute(
    \ cmd,
    \ lines,
    \ end_lineno,
    \ is_method,
    \ function('s:format_callback'),
    \ function('s:exit_callback')
    \ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
