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

GHQ="$HOME/src/github.com"

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
alias ls='eza -s modified -r'
# alias ls='ls -G'
alias la='ls -la --header --git'
alias l='eza -s modified -r'
alias ..='cd ..'
alias cp='cp -r'
alias rm=trash
alias awk=gawk
# alias touch=touch-alt

alias g='git'
alias ga='git add .'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias o='open'
# alias gh='gh browse'
alias gl='git see'
alias gg='ghq get -p'

alias s='cd "$HOME/sandbox"'
alias p='cd "$HOME/zcip"'
alias m='vim $HOME/Dropbox/Memo/memo.md'
alias json='curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d'
alias todo='open https://github.com/akameco/works/issues'
alias cra=create-react-app

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
source /usr/local/etc/profile.d/z.sh

alias pn=pnpm
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"


# ========================================
# 自動メンテナンス機能
# ========================================

# 前回実行時刻を記録するファイル
MAINTENANCE_LOG="$HOME/.last_maintenance"
MAINTENANCE_INTERVAL=$((7 * 24 * 60 * 60))  # 7日間（秒）

# メンテナンス関数
run_maintenance() {
    echo "🔧 メンテナンスを開始します..."
    
    # バックグラウンドで実行
    (
        {
            echo "=== Homebrew メンテナンス開始: $(date) ==="
            brew update && brew upgrade && brew cleanup && brew autoremove
            
            echo "=== パッケージマネージャー キャッシュクリーンアップ ==="
            npm cache clean --force 2>/dev/null
            yarn cache clean 2>/dev/null
            pnpm store prune 2>/dev/null
            
            echo "=== メンテナンス完了: $(date) ==="
            
            # 実行時刻を記録
            date +%s > "$MAINTENANCE_LOG"
        } >> /tmp/maintenance.log 2>&1
        
        # 通知
        osascript -e 'display notification "メンテナンスが完了しました" with title "システムメンテナンス"' 2>/dev/null
    ) &
}

# シェル起動時にチェック
check_maintenance() {
    local current_time=$(date +%s)
    
    # 前回実行時刻を取得
    if [[ -f "$MAINTENANCE_LOG" ]]; then
        local last_maintenance=$(cat "$MAINTENANCE_LOG")
        local elapsed=$((current_time - last_maintenance))
        
        # 7日以上経過していたら実行
        if [[ $elapsed -gt $MAINTENANCE_INTERVAL ]]; then
            echo "⏰ 前回のメンテナンスから7日以上経過しています"
            echo "   バックグラウンドでメンテナンスを実行します..."
            run_maintenance
        fi
    else
        # 初回実行
        echo "🆕 初回メンテナンスをバックグラウンドで実行します..."
        run_maintenance
    fi
}

# エイリアス: 手動実行用
alias maintenance='run_maintenance'
alias maintenance-log='tail -f /tmp/maintenance.log'
alias maintenance-status='[[ -f "$MAINTENANCE_LOG" ]] && echo "前回実行: $(date -r $(cat "$MAINTENANCE_LOG"))" || echo "未実行"'

# シェル起動時に自動チェック（初回のみ、サブシェルでは実行しない）
if [[ $SHLVL -eq 1 ]]; then
    check_maintenance
fi

# ========================================
# Git Worktree 便利関数
# ========================================

# ワークツリーのディレクトリに素早く移動
function gwt() {
  local branch=$1
  if [ -z "$branch" ]; then
    # 引数がない場合は一覧表示
    git worktree list
    return
  fi

  # ブランチ名の / を _ に置換してディレクトリ名を作成
  local dir_name=$(echo "$branch" | /usr/bin/sed 's/\//_/g')
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [ -z "$git_root" ]; then
    echo "エラー: Gitリポジトリ内で実行してください"
    return 1
  fi

  local worktree_path="$git_root/.local/__worktree/$dir_name"

  if [ -d "$worktree_path" ]; then
    cd "$worktree_path"
    echo "✓ [$branch] $worktree_path に移動しました"
  else
    echo "ワークツリーが見つかりません: [$branch] $worktree_path"
    echo ""
    echo "利用可能なワークツリー:"
    git worktree list
  fi
}

# fzf でワークツリーを選択して移動
function gwt-fzf() {
  which fzf > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "エラー: fzf がインストールされていません"
    echo "brew install fzf でインストールしてください"
    return 1
  fi

  # ブランチ名とパスのマッピングを作成
  local -A branch_to_path
  while IFS= read -r line; do
    local worktree_path=$(echo "$line" | /usr/local/bin/gawk '{print $1}')
    local branch=$(echo "$line" | /usr/local/bin/gawk '{print $3}' | /usr/bin/sed 's/[][]//g')
    if [ -z "$branch" ]; then
      branch="(detached)"
    fi
    branch_to_path[$branch]=$worktree_path
  done < <(git worktree list 2>/dev/null)

  # ブランチ名だけを表示
  local selected_branch=$(printf '%s\n' "${(@k)branch_to_path}" | fzf --height 40% --reverse --border --prompt="ワークツリーを選択: ")

  if [ -n "$selected_branch" ]; then
    local target_path="${branch_to_path[$selected_branch]}"

    if [ -n "$target_path" ] && [ -d "$target_path" ]; then
      cd "$target_path"
      echo "✓ $selected_branch に移動しました"
    fi
  fi
}

# ワークツリーのルートに戻る
function gwr() {
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$git_root" ]; then
    echo "エラー: Gitリポジトリ内で実行してください"
    return 1
  fi

  # .local/__worktree 配下にいるか確認
  if [[ "$PWD" == *"/.local/__worktree/"* ]]; then
    # ワークツリー内からメインのリポジトリルートに戻る
    cd "$git_root"
    echo "✓ メインリポジトリに戻りました"
  else
    # 既にメインリポジトリにいる
    echo "既にメインリポジトリにいます: $git_root"
  fi
}

# エイリアス
alias gw='gwt-fzf'
alias gwf='gwt-fzf'
alias gwl='git worktree list'

# マージ済みブランチとワークツリーを削除
function git-end() {
  local target_branch=${1:-dev}

  echo "Switching to $target_branch and pulling latest changes..."
  git checkout "$target_branch"
  git pull

  echo ""
  echo "Checking for merged branches and their worktrees..."

  # まず、マージ済みブランチのワークツリーをすべて削除
  git branch --merged "$target_branch" | sed 's/^[*+] *//' | grep -v "^$target_branch$" | while read branch; do
    # git worktree listから該当ブランチのワークツリーパスを取得
    local worktree=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$branch\$" | grep "^worktree " | cut -d " " -f 2)

    # ワークツリーが存在し、メインワークツリーでない場合は削除
    if [ -n "$worktree" ] && [ "$worktree" != "$(git rev-parse --show-toplevel)" ]; then
      echo "Removing worktree: $worktree (branch: $branch)"
      git worktree remove "$worktree" 2>/dev/null || echo "  ⚠ Failed to remove worktree (may have uncommitted changes)"
    fi
  done

  echo ""
  echo "Deleting merged branches..."

  # 次に、ブランチを削除
  git branch --merged "$target_branch" | sed 's/^[*+] *//' | grep -v "^$target_branch$" | while read branch; do
    echo "Deleting branch: $branch"
    git branch -d "$branch"
  done

  echo ""
  echo "✓ Cleanup completed."
}


alias gend git-end
