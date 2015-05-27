#!/bin/sh

# homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew install git

# ansible
brew install ansible
mkdir ~/.provi && cd $_
git clone https://github.com/akameco/dotfiles.git .
