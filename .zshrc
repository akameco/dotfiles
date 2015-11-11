# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

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

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# rbenv
eval "$(rbenv init -)"

## cdr
autoload -Uz add-zsh-hock
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook

## antigen
if [[ -f $HOME/.zsh/antigen/antigen.zsh ]]; then
  source $HOME/.zsh/antigen/antigen.zsh
  antigen bundle mollifier/anyframe # 追加
  antigen apply
fi

# alias j=anyframe-widget-cdr
# bindkey "^f" anyframe-widget-cdr
alias j=ecd

# direnv
eval "$(direnv hook zsh)"

# zsh-complete
fpath=(/usr/local/share/zsh-completions $fpath)
