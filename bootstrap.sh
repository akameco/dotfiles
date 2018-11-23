#!/bin/sh

set -e
set -u

git pull origin master;

PWD=`pwd`

doIt() {
  ln -sf ${PWD}/.vimrc ~/.vimrc
  ln -sf ${PWD}/.zshrc ~/.zshrc
  ln -sf ${PWD}/.zshenv ~/.zshenv
  ln -sf ${PWD}/.zprofile ~/.zprofile
  ln -sf ${PWD}/.gitconfig ~/.gitconfig
  ln -sf ${PWD}/.vim/snippets ~/.vim/snippets
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
  doIt;
else
  read -p "上書きする? (y/n)" -n 1;
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt;
  fi
fi;
unset doIt;
