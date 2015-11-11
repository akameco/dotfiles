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

function peco-cd() {
    local dir="$( find . -maxdepth 1 -type d | sed -e 's;\./;;' | peco )"
    if [ ! -z "$dir" ] ; then
        cd "$dir"
    fi
}

function p() {
  peco | while read LINE; do $@ $LINE; done
}

# alias k='cd $(ghq list -p | peco)'
alias o='git ls-files | peco | xargs open'
alias p="pushd +\$(dirs -p -v -l | sort -k 2 -k 1n | uniq -f 1 | sort -n | peco | head -n 1 | awk '{print \$1}')"
alias l='peco-cd'

# beepを鳴らさないようにする
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

# 補完を有効化
autoload -Uz compinit
compinit -u


# rbenv
eval "$(rbenv init - --no-rehash)"

# direnv
eval "$(direnv hook zsh)"

# docker-machine
# eval "$(docker-machine env default)"

# zsh-completions
# fpath=(/usr/local/share/zsh-completions $fpath)
# fpath=(/usr/local/share/zsh/site-functions $fpath)

function peco-z-search {
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
bindkey '^f' peco-z-search

alias rm="gomi"
alias awk='gawk'

# if (which zprof > /dev/null) ;then
  # zprof | less
# fi

