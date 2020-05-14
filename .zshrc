# zmodload zsh/zprof && zprof

# vim like key
bindkey -v

# emacs key
bindkey -M viins '\er' history-incremental-pattern-search-forward
bindkey -M viins '^?'  backward-delete-char
bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^B'  backward-char
bindkey -M viins '^D'  delete-char-or-list
bindkey -M viins '^E'  end-of-line
bindkey -M viins '^F'  forward-char
bindkey -M viins '^G'  send-break
bindkey -M viins '^H'  backward-delete-char
bindkey -M viins '^K'  kill-line
bindkey -M viins '^N'  down-line-or-history
bindkey -M viins '^P'  up-line-or-history
bindkey -M viins '^R'  history-incremental-pattern-search-backward
bindkey -M viins '^U'  backward-kill-line
bindkey -M viins '^W'  backward-kill-word
bindkey -M viins '^Y'  yank

autoload -Uz colors; colors
autoload -Uz add-zsh-hook
autoload -Uz terminfo

# theme
autoload -U promptinit && promptinit
prompt pure

# 重複パスを登録しない
typeset -U path cdpath fpath manpath

GHQ=`ghq root`/github.com

fpath=(/usr/local/share/zsh/site-functions $GHQ/zsh-users/zsh-completions/src $fpath)

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
setopt hist_ignore_space

# 履歴を共有する
setopt share_history

# docker-machine
# eval "$(docker-machine env default)"

# rbenv
# rbenv_init() {
	# eval "$(rbenv init - --no-rehash)"
# }

travis_init() {
	# rbenv_init

	[ -f /Users/akameco/.travis/travis.sh ] && source $HOME/.travis/travis.sh
	travis enable
}

# 使うときの呼ぶ
init() {
	if which pyenv > /dev/null; then
		eval "$(pyenv init -)";
	fi

	# direnv
	eval "$(direnv hook zsh)"

	# 例のアレ
	test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
}

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

# プラグイン読み込み
source $GHQ/robbyrussell/oh-my-zsh/lib/completion.zsh
# source $GHQ/rupa/z/z.sh
source $GHQ/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
source $GHQ/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# http://qiita.com/vintersnow/items/7343b9bf60ea468a4180#zcompile
if [ $DOTFILES/.zshrc -nt ~/.zshrc.zwc ]; then
  zcompile ~/.zshrc
fi

VIM_PROMPT="❯"
PROMPT='%(?.%F{magenta}.%F{red})${VIM_PROMPT}%f '

prompt_pure_update_vim_prompt() {
	zle || {
		print "error: pure_update_vim_prompt must be called when zle is active"
		return 1
	}
	VIM_PROMPT=${${KEYMAP/vicmd/❮}/(main|viins)/❯}
	zle .reset-prompt
}

function zle-line-init zle-keymap-select zle-line-finish {
	prompt_pure_update_vim_prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
zle -N zle-line-finish

eval "$(direnv hook zsh)"

# ME="akameco"
ME=`git config --get user.name`

gcd() {
	ghq get -p $1
	if [ `dirname "$1"` = "." ]; then
		cd `ghq root`/github.com/`git config --get user.name`/$1
	else
		cd `ghq root`/github.com/$1
	fi
}


add-js() {
	cd $GHQ/akameco/toy-box
	yarn run add-script $1
	cd js/$1
}

add-ts() {
	cd $GHQ/akameco/toy-box
	yarn run add-script --lang=ts $1
	cd ts/$1
}

dockerList() {
	docker ps -a | peco | cut -d" " -f1
}
plugins=(git yarn)

# alias
alias ls='exa'
# alias ls='ls -G'
alias la='ls -la --header --git'
alias l=ls
alias ..='cd ..'
alias cp='cp -r'
alias awk=gawk
alias rm=trash
alias touch=touch-alt

alias git=hub
alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias o='open'
alias gh=gh-home
alias gl='git see'
alias gg='ghq get -p'

alias s='cd "$HOME/sandbox"'
alias m='vim $HOME/Dropbox/Memo/memo.md'
alias json='curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d'
alias todo='open https://github.com/akameco/works/issues'
alias cra=create-react-app
source /usr/local/etc/profile.d/z.sh

# added by travis gem
[ -f /Users/akameco/.travis/travis.sh ] && source /Users/akameco/.travis/travis.sh

source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'

# alias npm=prioritize-yarn
alias wip="git commit --no-verify -m 'wip'"
alias da="direnv allow ."

TOY_BOX=$GHQ/akameco/toy-box
alias t='cd $TOY_BOX'

alias cdx='cd `find . -type d -name "node_modules" -prune -o -type d -name '.git' -prune -o -type d -print -maxdepth 3 | peco`'
