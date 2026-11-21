# husky の各フックの前に source される（$n はフック名、$@ はフックの引数）。
# husky のリポジトリは core.hooksPath が .husky/_ になり、グローバルのフックが動かないため、ここから呼ぶ。
case "$n" in
  post-checkout) "$HOME/.config/git/slim-worktree.sh" "$@" ;;
  post-merge) "$HOME/.config/git/clean-old-outputs.sh" ;;
esac
