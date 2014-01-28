jsdoc.vim
=========

jsdoc.vim generates JSDoc block comments based on a function signature.

This plugin based on https://gist.github.com/3903772#file-jsdoc-vim written by [NAKAMURA, Hisashi](https://gist.github.com/sunvisor)

Depending on your confuguration, jsdoc.vim will prompt for description, `@return` type and description. It will also prompt you for types and descriptions for each function `@param`.

## Usage
  1. Move cursor on `function` keyword line.
  2. Type `:JsDoc` or `<C-l>` which is default key mapping to insert JsDoc.
  3. Insert JsDoc above the `function` keyword line.

## Configuration
**g:jsdoc_allow_input_prompt** *default: 0*
Allow prompt for intaractive input.

**g:jsdoc_input_description** *default: 1*
Prompt for a function description

**g:jsdoc_additional_descriptions** *default: 0*
Prompt for a value for `@name`, add it to the JSDoc block comment along with the `@function` tag.

**g:jsdoc_return** *default: 1*
Add the `@return` tag.

**g:jsdoc_return_type** *default: 1*
Prompt for and add a type for the aforementioned `@return` tag.

**g:jsdoc_return_description** *default: 1*
Prompt for and add a description for the `@return` tag.

**g:jsdoc_default_mapping** *default: 1*
Set value to 0 to turn off default mapping of <C-l> :JsDoc<cr>
