#!/bin/sh

PWD=`pwd`

# symlink作成
ln -sf ${PWD}/.vimrc ~/.vimrc
ln -sf ${PWD}/.zshrc ~/.zshrc
ln -sf ${PWD}/.zshenv ~/.zshenv
ln -sf ${PWD}/.zprofile ~/.zprofile
ln -sf ${PWD}/.gitconfig ~/.gitconfig
ln -sf ${PWD}/.vim/snippets ~/.vim/snippets
ln -sf ${PWD}/gitmessage ~/.gitmessage

# brewがなければbrewを入れる
if [ ! `which brew` ]; then
  /usr/bin/ruby -e `curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`
  brew upgrade
  brew bundle
fi

# Install Neobundle
if [ ! -d ~/.vim/bundle ]; then
  mkdir -p ~/.vim/bundle
  git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
  echo 'Install NeoBundle'
fi

__setup() {
  # update config
  # git pull origin master;

  # Brew
  brew upgrade
  brew bundle

  # zsh
  if [ `which ghq` ]; then
    ghq import -p < ${PWD}/list/sh-list
  fi

  # npm
  if [ `which npm` ]; then
    cat ${PWD}/list/npm-global | xargs npm i -g
  fi
}


if [ "$1" == "-f" ]; then
  __setup
fi
