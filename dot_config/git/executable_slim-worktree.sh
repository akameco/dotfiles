#!/bin/sh
# 新しく作ったワークツリーを軽くする。post-checkout から引数をそのまま渡して呼ぶ
# （~/.config/git/hooks/post-checkout と ~/.config/husky/init.sh）。
#
# 1. git 管理の VRT スナップショット（*-snapshots/）を sparse-checkout で外す
#    ほかにも外す: git config --add slim-worktree.exclude 'path/to/dir/'
#    戻す: そのワークツリーで git sparse-checkout disable
#    外したファイルを消す（ストーリーを消したときなど）: git rm --sparse 'path/to/x.spec.ts-snapshots/<名前>*'
# 2. slim-worktree.clone に書いたパスのうち、本体と内容が同じファイルを本体からの APFS クローンに置き換える
#    （中身を共有するので容量を使わない。編集すればその時点で分かれる）
#    設定: git config --add slim-worktree.clone 'docs/screenshots/'
#    256KB 未満は飛ばす。変える: git config slim-worktree.cloneMinSize 65536
#
# 本体で sparse-checkout を有効にしておくと、git worktree add がその設定を引き継ぎ、
# 外したファイルを最初から書かない（1 を後からやるより速い）:
#    本体で git sparse-checkout set --no-cone '/*' '!*-snapshots/'
#
# 全部無効にする: SLIM_WORKTREE=0 git worktree add ...

[ "${SLIM_WORKTREE:-}" = 0 ] && exit 0
# ブランチの checkout で、直前の HEAD が null（= 新規のワークツリー）のときだけ
[ "$3" = 1 ] || exit 0
case "$1" in *[!0]*) exit 0 ;; esac
# 本体のワークツリー（clone 直後を含む）は対象外
[ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ] || exit 0

# --- 1. sparse-checkout ---
extra=$(git config --get-all slim-worktree.exclude)
if [ "$(git config --get core.sparseCheckout)" != true ] &&
  { [ -n "$extra" ] || git ls-files | grep -q -- '-snapshots/'; }; then
  # 外すパスを "!<path>" にして並べる（パスに空白がない前提）
  set -- '/*' '!*-snapshots/'
  for p in $extra; do set -- "$@" "!/${p#/}"; done
  git sparse-checkout set --no-cone "$@" &&
    echo "slim-worktree: *-snapshots/ ${extra:+$extra }を外しました（消すときは git rm --sparse <path>、戻すには git sparse-checkout disable）"
fi

# --- 2. 本体からのクローン ---
clone=$(git config --get-all slim-worktree.clone)
[ -n "$clone" ] || exit 0
main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
wt=$(git rev-parse --show-toplevel)
# 小さいファイルはクローンしても容量がほとんど減らず、置き換えの手間だけかかるので飛ばす（既定 256KB）
min=$(git config --get slim-worktree.cloneMinSize || echo 262144)
tmp=$(mktemp -d) || exit 0
n=0
for p in $clone; do
  # 本体側でそのパスが HEAD と違う（未コミットの変更・stage がある）なら、中身がずれている恐れがあるので飛ばす
  git -C "$main" diff --quiet HEAD -- "$p" || continue
  # "<hash> <path>" で、本体の HEAD（min 以上のもの）と新しいワークツリーの index を並べ、hash と path が一致するものだけ置き換える
  git -C "$main" -c core.quotepath=false ls-tree -r -l HEAD -- "$p" |
    awk -F'\t' -v min="$min" '{split($1,a," "); if (a[2]=="blob" && a[4]+0>=min) print a[3]"\t"$2}' | sort >"$tmp/main"
  git -c core.quotepath=false ls-files -s -- "$p" | awk -F'\t' '{split($1,a," "); print a[2]"\t"$2}' | sort |
    comm -12 - "$tmp/main" | cut -f2- | while IFS= read -r f; do
      [ -f "$wt/$f" ] && cp -c "$main/$f" "$wt/$f.slim.$$" && mv "$wt/$f.slim.$$" "$wt/$f" && echo x
    done >"$tmp/count"
  n=$((n + $(wc -l <"$tmp/count")))
done
/bin/rm -rf "$tmp"
git update-index -q --refresh >/dev/null 2>&1
[ "$n" -gt 0 ] && echo "slim-worktree: ${n} 件を本体からのクローンにしました（${clone}）"
exit 0
