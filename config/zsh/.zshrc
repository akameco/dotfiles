# ~/.config/zsh/.zshrc

if [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh"
fi

# 履歴設定
setopt histignorealldups sharehistory
HISTSIZE=5000
SAVEHIST=5000

# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

# mise (direnv代替 / ランタイム管理)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Starship prompt（超軽量モダン）
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide（cd の代替）
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# GitHub CLI
# eval "$(gh completion -s zsh)"

# ghq + fzf jump
zle -N fzf-zoxide-cd
bindkey '^G' fzf-zoxide-cd

command -v bat >/dev/null 2>&1 && alias cat='bat'

# 基本補完
autoload -Uz compinit && compinit -u

# Alias
alias ..='cd ..'

# macOS Finder 経由で安全にゴミ箱へ移動

alias rm=trash
alias realrm=/bin/rm
alias gs='git status'

# fzf でワークツリーを選択して移動
alias gw='gwt-fzf'

alias g=git
alias gc=git commit -m
export PATH="$HOME/.local/bin:$PATH"

export DEV_DIR="${HOME}/dev/github.com/akameco"
export DOT_DIR="${DEV_DIR}/dotfiles"

alias la='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons'
alias lad='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons --group-directories-first'
