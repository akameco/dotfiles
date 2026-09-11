# 指定コマンドが存在するか確認し、無ければヒントを表示する
require_command() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ -n "$hint" ]]; then
      echo "$hint" >&2
    else
      echo "$cmd が見つかりません" >&2
    fi
    return 1
  fi
}

# eza があればリッチ表示、無ければ組み込み ls を使う
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

# 指定したファイル/ディレクトリを Finder 経由でゴミ箱に移動する
trash() {
  if [[ $# == 0 ]]; then
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

gho() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch default_branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
    default_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo "")
    default_branch=${default_branch#origin/}

    if [[ -n "$default_branch" && "$branch" == "$default_branch" ]]; then
      gh repo view --web
      return
    fi
  fi

  gh pr view --web
}

# `git branch` 実行時に PR タイトルも表示する（引数なしのときだけ）
git__branch_list_with_pr_titles() {
  if ! command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    command git branch
    return $?
  fi

  local -a refs
  refs=("${(@f)$(command git for-each-ref refs/heads --format='%(HEAD)|%(refname:short)' 2>/dev/null)}")

  local -A pr_by_branch=()
  if command -v gh >/dev/null 2>&1; then
    local pr_lines
    pr_lines=$(
      gh pr list \
        --state all \
        --limit 200 \
        --json headRefName,number,title \
        --jq '.[] | [.headRefName, (.number|tostring), .title] | @tsv' 2>/dev/null || true
    )

    local head_ref pr_number pr_title
    while IFS=$'\t' read -r head_ref pr_number pr_title; do
      [[ -z "$head_ref" || -z "$pr_number" ]] && continue
      pr_title=${pr_title//$'\t'/ }
      pr_by_branch[$head_ref]="#${pr_number} ${pr_title}"
    done <<< "$pr_lines"
  fi

  local -a lines=()
  local ref head_mark branch_name
  for ref in "${refs[@]}"; do
    IFS='|' read -r head_mark branch_name <<< "$ref"
    [[ -z "$branch_name" ]] && continue

    local marker="  "
    [[ "$head_mark" == "*" ]] && marker="* "

    local pr="${pr_by_branch[$branch_name]}"
    if [[ -n "$pr" ]]; then
      lines+=("${marker}${branch_name}"$'\t'"${pr}")
    else
      lines+=("${marker}${branch_name}")
    fi
  done

  if command -v column >/dev/null 2>&1; then
    printf '%s\n' "${lines[@]}" | column -t -s $'\t'
  else
    printf '%s\n' "${lines[@]}"
  fi
}

# カレントブランチの PR タイトルを取得する
git__current_pr_title() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  if command -v gh >/dev/null 2>&1; then
    # 毎回たたくと重いので、ある程度のキャッシュを考慮したいが、まずはシンプルに取得
    gh pr view --json number,title --jq '"#\(.number) \(.title)"' 2>/dev/null
  fi
}

# Ghostty のステータスバーを更新する
update_ghostty_status_bar() {
  # Ghostty または tmux 内で実行されているか確認
  [[ -z "$GHOSTTY_RESOURCES_DIR" && "$TERM_PROGRAM" != "Ghostty" && -z "$TMUX" ]] && return

  local pr_title
  pr_title=$(git__current_pr_title)

  # Ghostty のステータスバー（またはウィンドウタイトル）を更新
  # tmux の場合はラップして送信
  if [[ -n "$TMUX" ]]; then
    if [[ -n "$pr_title" ]]; then
      printf "\ePtmux;\e\e]2;%s\a\e\\" "$pr_title"
    else
      printf "\ePtmux;\e\e]2;\a\e\\"
    fi
  else
    if [[ -n "$pr_title" ]]; then
      printf "\e]2;%s\a" "$pr_title"
    else
      printf "\e]2;\a"
    fi
  fi
}

# zsh の precmd フックに登録
autoload -Uz add-zsh-hook
add-zsh-hook precmd update_ghostty_status_bar

# `git` を薄くラップして、`git branch` (引数なし) のときだけ表示を拡張する
git() {
  if [[ $- == *i* && "$1" == "branch" && $# -eq 1 ]]; then
    git__branch_list_with_pr_titles
    return $?
  fi

  command git "$@"
}

# zoxide のインタラクティブ検索で選んだディレクトリに cd する
fzf-zoxide-cd() {
  require_command zoxide "zoxide が見つかりません (brew install zoxide)" || return 1
  local dir
  dir=$(zoxide query -i) || return
  BUFFER+="cd -- ${dir:q}"
  zle accept-line
}

# ghq のリポジトリ一覧を fzf で選んで cd する
ghq_cd() {
  require_command ghq "ghq が見つかりません (brew install ghq)" || return 1
  require_command fzf "fzf が見つかりません (brew install fzf)" || return 1

  local selected_dir
  selected_dir=$(ghq list -p | fzf --reverse --height 40%) || return
  [[ -n "$selected_dir" ]] && cd "$selected_dir"
}

gwt_usage_file() {
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
  printf '%s\n' "${state_dir}/git-worktree-usage.tsv"
}

gwt_cleanup_state_file() {
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
  printf '%s\n' "${state_dir}/git-worktree-cleanup.tsv"
}

gwt_cleanup_log_file() {
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
  printf '%s\n' "${state_dir}/git-worktree-cleanup.log"
}

gwt_usage_now() {
  zmodload zsh/datetime 2>/dev/null || return 1
  printf '%s\n' "$EPOCHSECONDS"
}

gwt_record_usage() {
  local git_root
  git_root=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0

  local usage_file
  usage_file=$(gwt_usage_file)
  /bin/mkdir -p "${usage_file:h}" 2>/dev/null || return 0

  local now
  now=$(gwt_usage_now) || return 0

  local -A latest_by_path=()
  if [[ -f "$usage_file" ]]; then
    local usage_ts usage_path
    while IFS=$'\t' read -r usage_ts usage_path; do
      [[ "$usage_ts" == <-> && -n "$usage_path" ]] || continue
      latest_by_path[$usage_path]="$usage_ts"
    done < "$usage_file"
  fi

  latest_by_path[$git_root]="$now"

  local path
  if [[ -e "$usage_file" ]]; then
    [[ -w "$usage_file" ]] || return 0
  else
    [[ -w "${usage_file:h}" ]] || return 0
  fi

  {
    for path in "${(@k)latest_by_path}"; do
      printf '%s\t%s\n' "${latest_by_path[$path]}" "$path"
    done
  } >| "$usage_file"
}

gwt_maybe_cleanup_merged_async() {
  setopt localoptions nobgnice

  local repo_root
  repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0

  local now
  now=$(gwt_usage_now) || return 0

  local state_file
  state_file=$(gwt_cleanup_state_file)
  /bin/mkdir -p "${state_file:h}" 2>/dev/null || return 0

  local last_run=0 state_repo state_ts
  if [[ -f "$state_file" ]]; then
    while IFS=$'\t' read -r state_repo state_ts; do
      [[ "$state_repo" == "$repo_root" && "$state_ts" == <-> ]] || continue
      last_run="$state_ts"
      break
    done < "$state_file"
  fi

  (( now - last_run >= 86400 )) || return 0

  local -A cleanup_by_repo=()
  if [[ -f "$state_file" ]]; then
    while IFS=$'\t' read -r state_repo state_ts; do
      [[ -n "$state_repo" && "$state_ts" == <-> ]] || continue
      cleanup_by_repo[$state_repo]="$state_ts"
    done < "$state_file"
  fi
  cleanup_by_repo[$repo_root]="$now"

  if [[ -e "$state_file" ]]; then
    [[ -w "$state_file" ]] || return 0
  else
    [[ -w "${state_file:h}" ]] || return 0
  fi

  local repo
  {
    for repo in "${(@k)cleanup_by_repo}"; do
      printf '%s\t%s\n' "$repo" "${cleanup_by_repo[$repo]}"
    done
  } >| "$state_file"

  local log_file
  log_file=$(gwt_cleanup_log_file)
  (
    printf '\n[%s] cleanup start: %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$repo_root"
    cd "$repo_root" && gwt-clean-merged --auto
  ) >> "$log_file" 2>&1 &!
}

if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd gwt_record_usage
  gwt_record_usage
fi

# git worktree を fzf で選択してジャンプする
gwt-fzf() {
  require_command fzf "fzf が見つかりません (brew install fzf)" || return 1

  if ! command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: git リポジトリ内で実行してください" >&2
    return 1
  fi

  gwt_maybe_cleanup_merged_async

  local current_worktree_path
  current_worktree_path=$(command git rev-parse --show-toplevel 2>/dev/null)

  local -A pr_by_branch=()
  if command -v gh >/dev/null 2>&1; then
    local pr_lines
    pr_lines=$(
      gh pr list \
        --state all \
        --limit 200 \
        --json headRefName,number,title \
        --jq '.[] | [.headRefName, (.number|tostring), .title] | @tsv' 2>/dev/null || true
    )

    local head_ref pr_number pr_title
    while IFS=$'\t' read -r head_ref pr_number pr_title; do
      [[ -z "$head_ref" || -z "$pr_number" ]] && continue
      pr_title=${pr_title//$'\t'/ }
      pr_by_branch[$head_ref]="#${pr_number} ${pr_title}"
    done <<< "$pr_lines"
  fi

  local -a worktree_entries=()
  local current_path=""
  local current_branch=""

  gwt_add_entry() {
    [[ -n "$current_worktree_path" && "$current_path" == "$current_worktree_path" ]] && return

    local branch_label="${current_branch:-"(detached)"}"

    local pr="${pr_by_branch[$branch_label]}"
    worktree_entries+=("${branch_label}"$'\t'"${pr}"$'\t'"${current_path}")
  }

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        if [[ -n "$current_path" ]]; then
          gwt_add_entry
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
          gwt_add_entry
          current_path=""
          current_branch=""
        fi
        ;;
    esac
  done < <(command git worktree list --porcelain 2>/dev/null)

  if [[ -n "$current_path" ]]; then
    gwt_add_entry
  fi

  if (( ${#worktree_entries[@]} == 0 )); then
    echo "エラー: git worktree が見つかりません" >&2
    return 1
  fi

  local usage_file
  usage_file=$(gwt_usage_file)
  local -A usage_by_path=()
  if [[ -f "$usage_file" ]]; then
    local usage_ts usage_path
    while IFS=$'\t' read -r usage_ts usage_path; do
      [[ -z "$usage_ts" || -z "$usage_path" ]] && continue
      usage_by_path[$usage_path]="$usage_ts"
    done < "$usage_file"
  fi

  local -a sorted_entries=()
  local entry entry_branch entry_pr entry_path entry_ts entry_sort_key entry_index=0
  for entry in "${worktree_entries[@]}"; do
    (( entry_index++ ))
    entry_branch="${entry%%$'\t'*}"
    entry_pr="${entry#*$'\t'}"
    entry_pr="${entry_pr%$'\t'*}"
    entry_path="${entry##*$'\t'}"
    entry_ts="${usage_by_path[$entry_path]:-0}"
    [[ "$entry_ts" == <-> ]] || entry_ts=0
    entry_sort_key=$(printf '%012d:%012d' $(( 999999999999 - entry_ts )) "$entry_index")
    sorted_entries+=("${entry_sort_key}"$'\t'"${entry_branch}"$'\t'"${entry_pr}"$'\t'"${entry_path}")
  done

  worktree_entries=("${(@o)sorted_entries}")

  local selected_entry
  selected_entry=$(printf '%s\n' "${worktree_entries[@]}" | fzf --height 40% --reverse --border --prompt="ワークツリーを選択: " --delimiter=$'\t' --with-nth=2,3,4)
  [[ -z "$selected_entry" ]] && return 0

  local selected_branch selected_pr target_path
  selected_branch="${selected_entry#*$'\t'}"
  selected_branch="${selected_branch%%$'\t'*}"
  selected_pr="${selected_entry#*$'\t'}"
  selected_pr="${selected_pr#*$'\t'}"
  selected_pr="${selected_pr%%$'\t'*}"
  target_path="${selected_entry##*$'\t'}"

  if [[ -n "$target_path" && -d "$target_path" ]]; then
    cd "$target_path"

    if [[ -n "$selected_branch" && "$selected_branch" != "(detached)" && "$selected_branch" != "(bare)" ]]; then
      local git_cmd
      git_cmd=$(command -v git) || true
      if [[ -n "$git_cmd" ]]; then
        local switch_output=""
        if switch_output=$("$git_cmd" switch "$selected_branch" 2>&1); then
          [[ -n "$switch_output" ]] && echo "$switch_output"
        else
          # 古い git / switch 不可環境向けのフォールバック
          if switch_output=$("$git_cmd" checkout "$selected_branch" 2>&1); then
            [[ -n "$switch_output" ]] && echo "$switch_output"
          else
            [[ -n "$switch_output" ]] && echo "$switch_output" >&2
          fi
        fi
      fi
    fi

    if [[ -n "$selected_pr" ]]; then
      echo "✓ ${selected_branch} (${selected_pr}) -> ${target_path} に移動しました"
    else
      echo "✓ ${selected_branch} -> ${target_path} に移動しました"
    fi
  fi
}

# git branch を fzf で選択して switch する
gb-fzf() {
  require_command fzf "fzf が見つかりません (brew install fzf)" || return 1

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: git リポジトリ内で実行してください" >&2
    return 1
  fi

  local -A pr_by_branch=()
  if command -v gh >/dev/null 2>&1; then
    local pr_lines
    pr_lines=$(
      gh pr list \
        --state all \
        --limit 200 \
        --json headRefName,number,title \
        --jq '.[] | [.headRefName, (.number|tostring), .title] | @tsv' 2>/dev/null || true
    )

    local head_ref pr_number pr_title
    while IFS=$'\t' read -r head_ref pr_number pr_title; do
      [[ -z "$head_ref" || -z "$pr_number" ]] && continue
      pr_title=${pr_title//$'\t'/ }
      pr_by_branch[$head_ref]="#${pr_number} ${pr_title}"
    done <<< "$pr_lines"
  fi

  local -a branches=()
  local ref head_mark branch_name

  while IFS='|' read -r head_mark branch_name; do
    [[ -z "$branch_name" ]] && continue

    local marker="  "
    [[ "$head_mark" == "*" ]] && marker="* "

    local pr="${pr_by_branch[$branch_name]}"
    if [[ -n "$pr" ]]; then
      branches+=("${marker}${branch_name}"$'\t'"${pr}")
    else
      branches+=("${marker}${branch_name}")
    fi
  done < <(git for-each-ref refs/heads --format='%(HEAD)|%(refname:short)' 2>/dev/null)

  if (( ${#branches[@]} == 0 )); then
    echo "ブランチが見つかりません" >&2
    return 1
  fi

  local selected_entry
  selected_entry=$(printf '%s\n' "${branches[@]}" | fzf --height 40% --reverse --border --prompt="ブランチを選択: " --delimiter=$'\t' --with-nth=1,2)
  [[ -z "$selected_entry" ]] && return 0

  local selected_branch
  selected_branch="${selected_entry%%$'\t'*}"
  selected_branch="${selected_branch:2}" # 先頭のマーカー(* またはスペース)を除去

  if [[ -n "$selected_branch" ]]; then
    local git_cmd
    git_cmd=$(command -v git) || true
    if [[ -n "$git_cmd" ]]; then
       if "$git_cmd" switch "$selected_branch" 2>/dev/null; then
         : # success
       else
         "$git_cmd" checkout "$selected_branch"
       fi
    fi
  fi
}

# 基準ブランチを判定する: origin/HEAD -> main -> master -> 現在のブランチ
gwt__detect_default_branch() {
  local git_cmd="$1"
  local default_branch

  default_branch=$("$git_cmd" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch=${default_branch#origin/}

  if [[ -z "$default_branch" ]]; then
    if "$git_cmd" show-ref --verify --quiet refs/heads/main; then
      default_branch="main"
    elif "$git_cmd" show-ref --verify --quiet refs/heads/master; then
      default_branch="master"
    else
      default_branch=$("$git_cmd" symbolic-ref --quiet --short HEAD 2>/dev/null)
    fi
  fi

  [[ -n "$default_branch" ]] || return 1
  printf '%s\n' "$default_branch"
}

# 基準ブランチにマージ済みの git worktree をまとめて削除する
gwt-clean-merged() {
  local auto_cleanup=0
  if [[ "$1" == "--auto" ]]; then
    auto_cleanup=1
  fi

  local git_cmd
  git_cmd=$(command -v git) || {
    echo "エラー: git コマンドが見つかりません" >&2
    return 1
  }

  if ! "$git_cmd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: git リポジトリ内で実行してください" >&2
    return 1
  fi

  local default_branch
  if ! default_branch=$(gwt__detect_default_branch "$git_cmd"); then
    echo "エラー: 基準ブランチを判定できません" >&2
    return 1
  fi

  local repo_root
  repo_root=$("$git_cmd" rev-parse --show-toplevel)

  if (( auto_cleanup )); then
    "$git_cmd" fetch --prune origin >/dev/null 2>&1 || true
  fi

  local current_branch
  current_branch=$("$git_cmd" symbolic-ref --quiet --short HEAD 2>/dev/null || true)

  local -a merged_branches=()
  while IFS= read -r br; do
    [[ -z "$br" || "$br" == "$default_branch" ]] && continue
    merged_branches+=("$br")
  done < <("$git_cmd" branch --merged "$default_branch" --format='%(refname:short)' 2>/dev/null)

  if (( ${#merged_branches[@]} == 0 )); then
    echo "マージ済みブランチが見つかりませんでした (基準: ${default_branch})"
    return 0
  fi

  local removed=0
  local remove_output branch_output
  # worktree 削除時にすでに落としたブランチを記録して二重削除を防ぐ
  local -a deleted_branches=()
  local wt_path wt_branch
  # porcelain 出力を path<TAB>branch に整形して読みやすくする
  while IFS=$'\t' read -r wt_path wt_branch; do
    [[ -z "$wt_path" || -z "$wt_branch" ]] && continue
    [[ "$wt_path" == "$repo_root" ]] && continue

    if printf '%s\n' "${merged_branches[@]}" | /usr/bin/grep -Fx -- "$wt_branch" >/dev/null; then
      echo "削除: ${wt_branch} (${wt_path})"
      local -a remove_args=("worktree" "remove" "$wt_path")
      (( auto_cleanup )) || remove_args+=("--force")

      if remove_output=$("$git_cmd" "${remove_args[@]}" 2>&1); then
        [[ -n "$remove_output" ]] && echo "$remove_output"
        ((removed++))

        if [[ "$current_branch" == "$wt_branch" ]]; then
          echo "ブランチ削除をスキップしました (現在チェックアウト中): ${wt_branch}"
        elif "$git_cmd" show-ref --verify --quiet "refs/heads/${wt_branch}"; then
          if branch_output=$("$git_cmd" branch -d "$wt_branch" 2>&1); then
            [[ -n "$branch_output" ]] && echo "$branch_output"
            deleted_branches+=("$wt_branch")
          else
            [[ -n "$branch_output" ]] && echo "$branch_output" >&2
          fi
        fi
      else
        [[ -n "$remove_output" ]] && echo "$remove_output" >&2
      fi
    fi
  done < <("$git_cmd" worktree list --porcelain | /usr/bin/awk '/^worktree /{wt=$2}/^branch refs\/heads\//{br=$2; sub("refs/heads/","",br); print wt "\t" br}')

  if (( removed == 0 )); then
    echo "削除対象のワークツリーはありませんでした (基準: ${default_branch})"
  else
    echo "完了: ${removed} 件のワークツリーを削除しました (基準: ${default_branch})"
  fi

  # worktree が存在しないマージ済みブランチもまとめて削除
  local br
  for br in "${merged_branches[@]}"; do
    [[ "$br" == "$current_branch" ]] && continue
    [[ "$br" == "$default_branch" ]] && continue
    if printf '%s\n' "${deleted_branches[@]}" | /usr/bin/grep -Fx -- "$br" >/dev/null; then
      continue
    fi

    if "$git_cmd" show-ref --verify --quiet "refs/heads/${br}"; then
      echo "ローカルブランチ削除: ${br}"
      if branch_output=$("$git_cmd" branch -d "$br" 2>&1); then
        [[ -n "$branch_output" ]] && echo "$branch_output"
      else
        [[ -n "$branch_output" ]] && echo "$branch_output" >&2
      fi
    fi
  done
}
