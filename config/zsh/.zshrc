# ~/.config/zsh/.zshrc

# 履歴設定
setopt histignorealldups sharehistory
HISTSIZE=5000
SAVEHIST=5000

# Alias
alias ..='cd ..'

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

# ghq + fzf (プロジェクト移動)
alias v='code "$(ghq list -p | fzf)"'

# ghq + fzf jump
function ghq_cd() {
  local selected_dir
  selected_dir=$(ghq list -p | fzf --reverse --height 40%) || return
  [ -n "$selected_dir" ] && cd "$selected_dir"
}

fzf-zoxide-cd() {
  local dir
  dir=$(zoxide query -i) || return   # 内部でfzfを使った対話検索
  BUFFER+="cd -- ${dir:q}"
  zle accept-line
}
zle -N fzf-zoxide-cd
bindkey '^G' fzf-zoxide-cd

command -v bat >/dev/null 2>&1 && alias cat='bat'

# 基本補完
autoload -Uz compinit && compinit -u

# macOS Finder 経由で安全にゴミ箱へ移動
trash() {
  if [ $# -eq 0 ]; then
    echo "Usage: trash <file_or_directory> [...]"
    return 1
  fi

  # 絶対パスにして配列へ
  local items=()
  for t in "$@"; do
    if [ -e "$t" ]; then
      items+=("$(cd "$(dirname "$t")" && pwd)/$(basename "$t")")
    else
      echo "trash: '$t' not found" >&2
    fi
  done
  [ ${#items[@]} -eq 0 ] && return 1

  # AppleScript の引数リストを構築（クォート安全）
  local list=""
  local first=1
  for p in "${items[@]}"; do
    # ダブルクォートをエスケープ
    local esc="${p//\"/\\\"}"
    if [ $first -eq 1 ]; then
      list="POSIX file \"${esc}\" as alias"
      first=0
    else
      list="${list}, POSIX file \"${esc}\" as alias"
    fi
  done

  # Finder に一括で渡す。標準出力（結果）は捨て、エラーは表示
  /usr/bin/osascript >/dev/null <<EOF
tell application "Finder"
  delete { ${list} }
end tell
EOF
}


alias rm=trash
alias realrm=/bin/rm
alias gs='git status'

# fzf でワークツリーを選択して移動
function gwt-fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "エラー: fzf がインストールされていません"
    echo "brew install fzf でインストールしてください"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: git リポジトリ内で実行してください" >&2
    return 1
  fi

  # fzf に渡す候補 (branch + path) を作成
  local -a worktree_entries=()
  local current_path=""
  local current_branch=""

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        if [ -n "$current_path" ]; then
          local branch_label="${current_branch:-"(detached)"}"
          worktree_entries+=("${branch_label}"$'\t'"${current_path}")
        fi
        current_path="${line#worktree }"
        current_branch=""
        ;;
      branch\ *)
        current_branch="${line#branch }"
        current_branch="${current_branch#refs/heads/}"
        ;;
      detached)
        current_branch="(detached)"
        ;;
      bare)
        current_branch="(bare)"
        ;;
      '')
        if [ -n "$current_path" ]; then
          local branch_label="${current_branch:-"(detached)"}"
          worktree_entries+=("${branch_label}"$'\t'"${current_path}")
          current_path=""
          current_branch=""
        fi
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)

  if [ -n "$current_path" ]; then
    local branch_label="${current_branch:-"(detached)"}"
    worktree_entries+=("${branch_label}"$'\t'"${current_path}")
  fi

  if [ ${#worktree_entries[@]} -eq 0 ]; then
    echo "エラー: git worktree が見つかりません" >&2
    return 1
  fi

  local selected_entry
  selected_entry=$(printf '%s\n' "${worktree_entries[@]}" | fzf --height 40% --reverse --border --prompt="ワークツリーを選択: " --delimiter=$'\t' --with-nth=1,2)
  [ -z "$selected_entry" ] && return 0

  local selected_branch="${selected_entry%%$'\t'*}"
  local target_path="${selected_entry#*$'\t'}"

  if [ -n "$target_path" ] && [ -d "$target_path" ]; then
    cd "$target_path"
    echo "✓ ${selected_branch} -> ${target_path} に移動しました"
  fi
}
alias gw='gwt-fzf'

alias g=git
alias gc=git commit -m
export PATH="$HOME/.local/bin:$PATH"

export DEV_DIR="${HOME}/dev/github.com/akameco"
export DOT_DIR="${DEV_DIR}/dotfiles"

ls() {
  local hide='Applications|Desktop|Documents|Downloads|Movies|Music|Pictures|Public|Library'
  if (( $# == 0 )) && [[ $PWD == $HOME ]]; then
    eza --icons --group-directories-first --grid --color=auto --ignore-glob "$hide"
  else
    eza --icons --group-directories-first --grid --color=auto "$@"
  fi
}

alias la='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons'
alias lad='eza -alh --no-user --time-style=long-iso --sort=modified --reverse --icons --group-directories-first'
