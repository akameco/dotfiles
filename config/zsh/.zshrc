# ~/.config/zsh/.zshrc

if [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh"
fi

# 履歴設定
setopt histignorealldups sharehistory
HISTFILE="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_history"
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

# 基本補完 (zcompdump が最新ならキャッシュを再利用)
autoload -Uz compinit
zmodload zsh/complist 2>/dev/null
_zcompdump_file="${ZDOTDIR:-$HOME/.config/zsh}/.zcompdump"
if [[ ! -f "$_zcompdump_file" || "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc" -nt "$_zcompdump_file" ]]; then
  compinit
else
  compinit -C
fi
unset _zcompdump_file

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

if command -v eza >/dev/null 2>&1; then
  alias la='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons'
  alias lad='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons --group-directories-first'
else
  alias la='ls -alh'
  alias lad='ls -alh'
fi
