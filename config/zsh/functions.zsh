# shell functions used by ~/.config/zsh/.zshrc

function ghq_cd() {
  if ! command -v ghq >/dev/null 2>&1; then
    echo "ghq が見つかりません (brew install ghq)" >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf が見つかりません (brew install fzf)" >&2
    return 1
  fi

  local selected_dir
  selected_dir=$(ghq list -p | fzf --reverse --height 40%) || return
  [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

fzf-zoxide-cd() {
  local dir
  dir=$(zoxide query -i) || return
  BUFFER+="cd -- ${dir:q}"
  zle accept-line
}

trash() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: trash <file_or_directory> [...]"
    return 1
  fi

  local items=()
  local target
  for target in "$@"; do
    if [[ -e "$target" ]]; then
      local abs_path
      abs_path=$(cd "$(dirname "$target")" && pwd)/$(basename "$target")
      items+=("$abs_path")
    else
      echo "trash: '$target' not found" >&2
    fi
  done
  [[ ${#items[@]} -eq 0 ]] && return 1

  local list=""
  local first=1
  local path
  for path in "${items[@]}"; do
    local esc="${path//\"/\\\"}"
    if (( first )); then
      list="POSIX file \"${esc}\" as alias"
      first=0
    else
      list="${list}, POSIX file \"${esc}\" as alias"
    fi
  done

  /usr/bin/osascript >/dev/null <<EOFAPPLE
tell application "Finder"
  delete { ${list} }
end tell
EOFAPPLE
}

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

  local -a worktree_entries=()
  local current_path=""
  local current_branch=""

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        if [[ -n "$current_path" ]]; then
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
        if [[ -n "$current_path" ]]; then
          local branch_label="${current_branch:-"(detached)"}"
          worktree_entries+=("${branch_label}"$'\t'"${current_path}")
          current_path=""
          current_branch=""
        fi
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)

  if [[ -n "$current_path" ]]; then
    local branch_label="${current_branch:-"(detached)"}"
    worktree_entries+=("${branch_label}"$'\t'"${current_path}")
  fi

  if (( ${#worktree_entries[@]} == 0 )); then
    echo "エラー: git worktree が見つかりません" >&2
    return 1
  fi

  local selected_entry
  selected_entry=$(printf '%s\n' "${worktree_entries[@]}" | fzf --height 40% --reverse --border --prompt="ワークツリーを選択: " --delimiter=$'\t' --with-nth=1,2)
  [[ -z "$selected_entry" ]] && return 0

  local selected_branch="${selected_entry%%$'\t'*}"
  local target_path="${selected_entry#*$'\t'}"

  if [[ -n "$target_path" && -d "$target_path" ]]; then
    cd "$target_path"
    echo "✓ ${selected_branch} -> ${target_path} に移動しました"
  fi
}

ls() {
  if command -v eza >/dev/null 2>&1; then
    local hide='Applications|Desktop|Documents|Downloads|Movies|Music|Pictures|Public|Library'
    if (( $# == 0 )) && [[ $PWD == $HOME ]]; then
      command eza --icons --group-directories-first --grid --color=auto --ignore-glob "$hide"
    else
      command eza --icons --group-directories-first --grid --color=auto "$@"
    fi
    return
  fi

  command ls "$@"
}
