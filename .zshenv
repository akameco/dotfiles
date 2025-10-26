export HISTSIZE=5000
export SAVEHIST=5000
export HISTFILE=$HOME/.zsh_history

export GOPATH=$HOME/src

# miniconda=miniconda3-4.1.11


path=(
	$GOPATH/bin
	$HOME/.cargo/bin
	# $PYENV_ROOT/versions/$miniconda/bin
	$path
)
. "$HOME/.cargo/env"
