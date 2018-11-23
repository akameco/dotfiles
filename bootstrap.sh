#!/bin/sh

PWD=`pwd`

# symlink作成
ln -sf ${PWD}/.vimrc ~/.vimrc
ln -sf ${PWD}/.zshrc ~/.zshrc
ln -sf ${PWD}/.zshenv ~/.zshenv
ln -sf ${PWD}/.zprofile ~/.zprofile
ln -sf ${PWD}/.gitconfig ~/.gitconfig
ln -sf ${PWD}/.vim/snippets ~/.vim/snippets

# Install Neobundle
if [ ! -d ~/.vim/bundle ]; then
  mkdir -p ~/.vim/bundle
  git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
  echo 'Install NeoBundle'
fi;

# npm
if [ `which npm` ]; then
  cat ${PWD}/js/npm-global | xargs npm i -g
fi

# git pull origin master;
