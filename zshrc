# zmodload zsh/zprof
# antigen
source $HOME/.zshrc.antigen

# git
alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gco='git checkout'
alias gp='git push'

# peco
function peco-select-history() {
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

function p() {
	peco | while read LINE; do $@ $LINE; done
}

function ghq_list() {
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

# docker-machine
# eval "$(docker-machine env default)"

# zsh-completions
# fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/usr/local/share/zsh/site-functions $fpath)

# 補完を有効化
autoload -Uz compinit
compinit -u

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

# alias rm="gomi"
alias awk='gawk'

# if (which zprof > /dev/null) ;then
# zprof | less
# fi

alias r='rails'
alias rb='ruby'
# alias n='node'
alias o='open'
alias da='direnv allow'
alias chrome='open -a "/Applications/Google Chrome.app"'
alias oc=chrome
# alias npm-pixiv='npm-pixiv'
alias v='vim'
alias vi='vim'

getMyRepo () {
	# local repo=$1
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

alias gge=git-grep-edit
alias pgup='postgres -D /usr/local/var/postgres'
setopt nonomatch
export PATH="$(brew --prefix homebrew/php/php70)/bin:$PATH"

cpp () {
	g++ $1 && ./a.out
}

dm() {
	eval "$(docker-machine env default)"
}

alias se=http-server

# .zshrc
autoload -U promptinit && promptinit
prompt pure
