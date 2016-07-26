# zmodload zsh/zprof
# antigen
source $HOME/.zshrc.antigen

# zsh-completions
# fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/usr/local/share/zsh/site-functions $fpath)

# 補完を有効化
autoload -Uz compinit
compinit -u


# alias
## git
alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gco='git checkout'
alias gp='git push'

alias awk='gawk'
alias o='open'
alias r='rails'
alias rb='ruby'
alias da='direnv allow'
alias chrome='open -a "/Applications/Google Chrome.app"'
alias oc=chrome
alias v='vim'
alias vi='vim'
alias gge=git-grep-edit
alias pgup='postgres -D /usr/local/var/postgres'
alias se=http-server

# theme
autoload -U promptinit && promptinit
prompt pure

# peco
peco-select-history() {
	local tac
	if which tac > /dev/null; then
		tac="tac"
	else
		tac="tail -r"
	fi
	BUFFER=$(\history -n 1 | \
		eval $tac | \
		peco --query "$LBUFFER")
	CURSOR=$#BUFFER
	zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

p() {
	peco | while read LINE; do $@ $LINE; done
}

ghq_list() {
	cd $(ghq list -p | peco)
	zle clear-screen
}

zle -N ghq_list
bindkey "^k" ghq_list
alias k=ghq_list

setopt nolistbeep

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end

# 登録済コマンド行は古い方を削除
setopt hist_ignore_all_dups

# rbenv
eval "$(rbenv init - --no-rehash)"

# direnv
eval "$(direnv hook zsh)"

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

getMyRepo () {
	ghq get -p "akameco/$1"
}
alias m=getMyRepo

setTerminalText () {
	# echo works in bash & zsh
	local mode=$1 ; shift
	echo -ne "\033]$mode;$@\007"
}
stt_both  () { setTerminalText 0 $@; }
stt_tab   () { setTerminalText 1 $@; }
stt_title () { setTerminalText 2 $@; }
DISABLE_AUTO_TITLE="true"

# added by travis gem
[ -f /Users/akameco/.travis/travis.sh ] && source /Users/akameco/.travis/travis.sh

setopt nonomatch
export PATH="$(brew --prefix homebrew/php/php70)/bin:$PATH"

cpp () {
	g++ $1 && ./a.out
}

dm() {
	eval "$(docker-machine env default)"
}

# docker-machine
# eval "$(docker-machine env default)"

# if (which zprof > /dev/null) ;then
# zprof | less
# fi

