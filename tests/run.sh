#!/bin/sh

###############################################################################
#                            Execute all test case                            #
###############################################################################
: "${VIM_EXE:=vim}"

# If nvim is available in PATH, then we prefer to use nvim
# since it works better with nodemon
if hash nvim 2>/dev/null ; then
  VIM_EXE="nvim"
fi

# Open vim with readonly mode just to execute all *.vader tests.
$VIM_EXE -Nu minimal_vimrc -R '+Vader! *.vader'
