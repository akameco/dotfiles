#!/bin/sh
# 本体と各ワークツリーで、slim-worktree.clean に書いたパス（ワークツリー直下からの glob）のうち、3 日より古いものを消す。
# 設定（リポジトリごと）: git config --add slim-worktree.clean '.local/vrt-diff-*'
# post-merge から呼ぶ（~/.config/git/hooks/post-merge と ~/.config/husky/init.sh）。

pats=$(git config --get-all slim-worktree.clean) || exit 0

git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | while IFS= read -r w; do
  for p in $pats; do
    # ワークツリーの外を指すパターンは無視する
    case "$p" in /* | *..*) continue ;; esac
    for d in "$w"/$p; do
      [ -e "$d" ] || continue
      [ -n "$(find "$d" -maxdepth 0 -mtime +3)" ] && /bin/rm -rf "$d"
    done
  done
done
exit 0
