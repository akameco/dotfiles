# ~/.config/zsh/.zshrc

if [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh"
fi

# 履歴設定
setopt histignorealldups sharehistory
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
HISTFILE="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000

# Homebrew (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
fi

# 対話シェル専用設定
if [[ $- == *i* ]]; then
  # mise (direnv代替 / ランタイム管理)
  if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
  fi

  # Starship prompt（超軽量モダン）
  if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
  fi

  # zoxide（cd の代替）
  if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
  fi

  # ghq + fzf jump
  if [[ -n ${functions[fzf-zoxide-cd]} ]]; then
    zle -N fzf-zoxide-cd
    bindkey '^G' fzf-zoxide-cd
  fi

  # GitHub CLI 補完 (必要ならアンコメント)
  # (( $+commands[gh] )) && eval "$(gh completion -s zsh)"
fi

(( $+commands[bat] )) && alias cat='bat'

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

# 安全な削除
alias rm='trash'
alias realrm='/bin/rm'

# Git 操作用
alias g='git'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git pull'
alias gw='gwt-fzf'  # fzf でワークツリーを選択して移動

alias vim='nvim'
alias vi='nvim'
alias v.='nvim .'
alias m='nvim ~/Memo/memo.md'

alias ai='claude'

if (( $+commands[nvim] )); then
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

export PATH="$HOME/.local/bin:$PATH"

export DEV_DIR="${HOME}/dev/github.com/akameco"
export DOT_DIR="${DEV_DIR}/dotfiles"

if (( $+commands[eza] )); then
  alias la='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons'
  alias lad='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons --group-directories-first'
else
  alias la='ls -alh'
  alias lad='ls -alh'
fi
