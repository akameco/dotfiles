# zmodload zsh/zprof && zprof

bindkey -e

# theme
autoload -U promptinit && promptinit
prompt pure

GHQ=$HOME/src/github.com
fpath=(/usr/local/share/zsh/site-functions $GHQ/zsh-completions/src $fpath)

# 補完を有効化
autoload -Uz compinit
compinit -u

# http://qiita.com/kwgch/items/445a230b3ae9ec246fcb
setopt nonomatch
setopt no_beep
setopt nolistbeep
# http://qiita.com/syui/items/c1a1567b2b76051f50c4
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt hist_ignore_all_dups 

# docker-machine
# eval "$(docker-machine env default)"

# rbenv
# eval "$(rbenv init - --no-rehash)"

# direnv
eval "$(direnv hook zsh)"

# travis
[ -f /Users/akameco/.travis/travis.sh ] && source $HOME/.travis/travis.sh


# alias
alias vz='vim ~/.zshrc'
alias sz='source ~/.zshrc'

alias ls='ls -G'
alias awk=gawk
alias vi=vim
alias ..='cd ..'
alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias o='open'
alias da='direnv allow'
alias chrome='open -a "/Applications/Google Chrome.app"'
alias oc=chrome
alias gge=git-grep-edit
alias pgup='postgres -D /usr/local/var/postgres'
alias gh=gh-home
alias gg='ghq get -p'
alias s='source'
alias cg='cd "$GHQ/akameco"'
alias cs='cd "$HOME/sandbox"'

# peco
h() {
	BUFFER=$(history -n 1 | tail -r | peco --query "$LBUFFER")
	CURSOR="$#BUFFER"
}
zle -N h
bindkey '^r' h

# ghq-list
k() {
	local repo=$(ghq list -p | cut -d "/" -f 6- | peco)
	cd "$HOME/src/github.com/$repo"
}

peco-z-search () {
	which peco z > /dev/null
	if [ $? -ne 0 ]; then
		echo "Please install peco and z"
		return 1
	fi
	local res=$(z | sort -rn | cut -c 12- | peco)
	if [ -n "$res" ]; then
		BUFFER+="cd $res"
		zle accept-line
	else
		return 1
	fi
}

zle -N peco-z-search
bindkey '^g' peco-z-search

m() {
	ghq get -p "akameco/$1"
}

cpp () {
	g++ $1 && ./a.out
}

dm() {
	eval "$(docker-machine env default)"
}

u() {
	cd ./$(git rev-parse --show-cdup)
	if [ $# = 1 ]; then
		cd $1
	fi
}

source $GHQ/robbyrussell/oh-my-zsh/lib/completion.zsh
source $GHQ/rupa/z/z.sh
source $GHQ/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# if (which zprof > /dev/null) ;then
	# zprof | less
# fi
