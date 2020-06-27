#!/bin/sh
: "${VIM_EXE:=vim}"

# download test dependency if needed
if [[ ! -d "./vader.vim" ]]; then
  git clone https://github.com/junegunn/vader.vim.git vader.vim
fi

# If nvim is available in PATH, then we prefer to use nvim
# since it works better with nodemon
if hash nvim 2>/dev/null ; then
  VIM_EXE="nvim"
fi

# Open vim with readonly mode just to execute all *.vader tests.
$VIM_EXE -Nu vimrc -R '+Vader! *.vader'
