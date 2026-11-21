# husky の各フックの前に source される（$n はフック名、$@ はフックの引数）。
# husky のリポジトリは core.hooksPath が .husky/_ になり、グローバルのフックが動かないため、ここから呼ぶ。
case "$n" in
  post-checkout) "$HOME/.config/git/slim-worktree.sh" "$@" ;;
  post-merge)
    "$HOME/.config/git/clean-old-outputs.sh"
    # マージ済み・放置されたワークツリーを消す（グローバルの post-merge と同じ。--force は付けない）
    if command -v zsh >/dev/null 2>&1; then
      zsh -lc 'source ~/.config/zsh/functions.zsh && gwt-clean-merged --auto' >/dev/null 2>&1 || true
    fi
    ;;
esac
