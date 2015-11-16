jsdoc.vim
=========

jsdoc.vim generates [JSDoc](http://usejsdoc.org/) block comments based on a function signature.

![image](https://github.com/heavenshell/vim-jsdoc/wiki/images/vim-jsdoc-screencast-preview.gif)

This plugin based on https://gist.github.com/3903772#file-jsdoc-vim written by [NAKAMURA, Hisashi](https://gist.github.com/sunvisor)

Depending on your configuration, jsdoc.vim will prompt for description, `@return` type and description. It will also prompt you for types and descriptions for each function `@param`.

Data type tab completion supported for parameter and return types
* currently: `boolean`, `null`, `undefined`, `number`, `string`, `symbol`, `object`, `function`, `array`

## Usage

  1. Move cursor on `function` keyword line.
  2. Type `:JsDoc` to insert JSDoc.
  3. Insert JSDoc above the `function` keyword line.

## Configuration

Option                                  | Default | Description
:-------------------------------------- | :------ | :----------
**g:jsdoc_allow_input_prompt**          | 0       | Allow prompt for interactive input.
**g:jsdoc_input_description**           | 0       | Prompt for a function description
**g:jsdoc_additional_descriptions**     | 0       | Prompt for a value for `@name`, add it to the JSDoc block comment along with the `@function` tag.
**g:jsdoc_return**                      | 1       | Add the `@return` tag.
**g:jsdoc_return_type**                 | 1       | Prompt for and add a type for the aforementioned `@return` tag.
**g:jsdoc_return_description**          | 1       | Prompt for and add a description for the `@return` tag.
**g:jsdoc_access_descriptions**         | 0       | Set value to 1 to turn on access tags like `@access <private|public>`. Set value to 2 to turn on access tags like `@<private|public>`
**g:jsdoc_underscore_private**          | 0       | Set value to 1 to turn on detecting underscore starting functions as private convention
**g:jsdoc_allow_shorthand**             | 0       | Set value to 1 to allow ECMAScript6 shorthand syntax. Since ver `0.5.0` deprecated. Use `g:jsdoc_enable_es6` instead.
**g:jsdoc_param_description_separator** | ' '     | Characters used to separate `@param` name and description.
**g:jsdoc_custom_args_hook**            | {}      | Override default type and description. See help more detail.
**g:jsdoc_type_hook**                   | {}      | Allow to insert default description depending on the type.
**g:jsdoc_enable_es6**                  | 0       | Enable to use ECMAScript6's Shorthand function, Arrow function.

## Keymap
Since version `0.3`, `g:jsdoc_default_mapping` was removed.

Add following setting to .vimrc if you want same behavior as version `0.2.1`.
```viml
nmap <silent> <C-l> <Plug>(jsdoc)
```

Alternatively, you could add the following setting to your .vimrc to search for the last `function` declaration
and puts your jsdoc above it:
```viml
nmap <silent> <C-l> ?function<cr>:noh<cr><Plug>(jsdoc)
```
