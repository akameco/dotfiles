#!/bin/sh

PWD=`pwd`

ln -sf ${PWD}/.gitconfig ~/
ln -sf ${PWD}/.vimrc ~/
ln -sf ${PWD}/.gvimrc ~/
ln -sf ${PWD}/.vimshrc ~/
ln -sf ${PWD}/.vimperatorrc ~/
ln -sf ${PWD}/.gvimrc ~/
ln -sf ${PWD}/.zshrc ~/
ln -sf ${PWD}/vim/snippets ~/.vim/snippets

# install Neobundle
[ ! -d ~/.vim/bundle ] && mkdir -p ~/.vim/bundle && git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim

echo complete setting!
