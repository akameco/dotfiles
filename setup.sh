#!/bin/sh

PWD=`pwd`

ln -sf ${PWD}/zshrc ~/.zshrc
ln -sf ${PWD}/zshenv ~/.zshenv
ln -sf ${PWD}/zprofile ~/.zprofile
ln -sf ${PWD}/gitconfig ~/.gitconfig
ln -sf ${PWD}/vimrc ~/.vimrc
ln -sf ${PWD}/gvimrc ~/.gvimrc
ln -sf ${PWD}/vimperatorrc ~/.vimperatorrc
ln -sf ${PWD}/vim/snippets ~/.vim/snippets

# install Neobundle
# [ ! -d ~/.vim/bundle ] && mkdir -p ~/.vim/bundle && git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim

echo complete setting!
