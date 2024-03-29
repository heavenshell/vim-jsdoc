" File: jsdoc.vim
" Author: NAKAMURA, Hisashi <https://github.com/sunvisor>
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-jsdoc/
" Description: Generate JSDoc to your JavaScript, TypeScript file.
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

" version check
if !has('nvim') && (!has('channel') || !has('job'))
  echoerr '+channel and +job are required for jsdoc.vim'
  finish
endif

command! -range=0 JsDoc call jsdoc#insert(<q-args>, <count>, <line1>, <line2>)
command! JsDocFormat call jsdoc#format()
nnoremap <silent> <buffer> <Plug>(jsdoc) :call jsdoc#insert()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
