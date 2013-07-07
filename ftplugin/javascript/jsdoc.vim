" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Modifyed: Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.0.5
" WebPage:  http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JsDoc to your JavaScript file.
" License: BSD, see LICENSE for more details.

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -buffer -complete=customlist,jsdoc#insert JsDoc call jsdoc#insert()

if !exists('g:jsdoc_default_mapping')
  let g:jsdoc_default_mapping = 1
endif
nnoremap <silent> <buffer> <Plug>(jsdoc) :call jsdoc#insert()<CR>
if !hasmapto('<Plug>(jsdoc)') && g:jsdoc_default_mapping
  nmap <silent> <C-l> <Plug>(jsdoc)
endif

let &cpo = s:save_cpo
unlet s:save_cpo

