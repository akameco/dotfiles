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

# alias
alias vz='vim ~/.zshrc'
alias sz='source ~/.zshrc'

alias ls='ls -G'
alias l=ls
alias awk=gawk
alias vi=vim
alias ..='cd ..'
alias t='tig'
alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias o='open'
alias da='direnv allow'
alias gge=git-grep-edit
# alias pgup='postgres -D /usr/local/var/postgres'
alias gh=gh-home
alias gl='git see'
alias gg='ghq get -p'
# alias d='cd ~/dotfiles'
alias c='cd "$GHQ/akameco"'
alias s='cd "$HOME/sandbox"'
alias toy='cd "$GHQ/akameco/toy-box"'
alias sl='imgcat /Users/akameco/Pictures/rezero/10000/hamasa00-レム.png'
alias a='atom-beta'

alias plugin="/usr/local/Cellar/elasticsearch/2.4.0/libexec/bin/plugin"

alias sp='speed-test'
alias la='ls -la'
# alias npm='prioritize-yarn'
# alias npm=prioritize-yarn
alias y='yarn'
alias m='vim $HOME/Dropbox/Memo/memo.md'

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

cpp () {
	g++ $1 && ./a.out
}

# u() {
	# cd ./$(git rev-parse --show-cdup)
	# if [ $# = 1 ]; then
		# cd $1
	# fi
# }

d() {
	cd $GHQ/akameco/daily-report/_posts
	local t=$(date +"%Y-%m-%d")
	local f="$t-report.md"
	if [ -e $f ]; then
		vim $f
	else
		touch $f
	fi
}

# プラグイン読み込み
source $GHQ/robbyrussell/oh-my-zsh/lib/completion.zsh
source $GHQ/rupa/z/z.sh
source $GHQ/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
source $GHQ/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# http://qiita.com/vintersnow/items/7343b9bf60ea468a4180#zcompile
if [ $DOTFILES/.zshrc -nt ~/.zshrc.zwc ]; then
  zcompile ~/.zshrc
fi

# if (which zprof > /dev/null) ;then
	# zprof | less
# fi

open-github() {
	open https://github.com/$1
}

alias og='open https://github.com/akameco'
alias ogt='open https://github.com/trending'
alias otw='open https://tweetdeck.twitter.com/#'

get-ghq-repo () {
	ghq get -p $1
	cd $GHQ/$1
}

alias gr=get-ghq-repo

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

# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

qiita-items() {
	curl "qiita.com/api/v2/items?query=user%3A$1&per_page=100"
}

alias rm=trash
eval "$(direnv hook zsh)"
alias touch=touch-alt
alias b='cd "$GHQ/akameco/blog"'
alias cp='cp -r'

# ME="akameco"
ME=`git config --get user.name`

gcd() {
	ghq get -p $1
	if [ `dirname "$1"` = "." ]; then
		cd $GHQ/$ME/$1
	else
		cd $GHQ/$1
	fi
}

alias json='curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d'
alias e='cd $GHQ/akameco/toy-box'

curl-local() {
  curl "http://localhost:$1"
}
alias cl=curl-local

alias today='open https://github.com/akameco/works/issues?q=is%3Aissue+is%3Aopen+label%3A%E4%BB%8A%E6%97%A5%E4%B8%AD'
alias todo='open https://github.com/akameco/works/issues'

alias tw='yarn run test:watch --coverage'

nippo() {
	cd $GHQ/akameco/blog
	yarn run nippo
}

add-article() {
	cd $GHQ/akameco/blog
	yarn run add-page $1
}

add-js() {
	cd $GHQ/akameco/toy-box
	yarn run add-script $1
	cd js/$1
}

git-root() {
	if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
		cd `pwd`/`git rev-parse --show-cdup`
	fi
}

git-change-cd() {
	cd `git ls-files -m -o --exclude-standard | peco | xargs dirname`
}

alias groot=git-root
alias gro=git-root
alias gccd=git-change-cd
alias gge=git-grep-edit
alias git=hub
alias gh='git browse'
alias ni=nippo
alias aa=add-article
alias cra=create-react-app

# tabtab source for yarn package
# uninstall by removing these lines or running `tabtab uninstall yarn`
[[ -f /Users/akameco/.config/yarn/global/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh ]] && . /Users/akameco/.config/yarn/global/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh

dockerList() {
	docker ps -a | peco | cut -d" " -f1
}
