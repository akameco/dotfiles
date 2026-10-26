#!/bin/zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Homebrew update & storage cleanup start ==="

# 失敗した手順を集め、最後の要約と通知に使う。失敗しても残りの手順は続ける
failed=()
run_step() {
  local label=$1
  shift
  "$@" || { echo "==> $label failed (exit $?)"; failed+=("$label"); }
}

# mise の出力の写しを取り、minimum_release_age で見送った版を最後に数える
mise_log=$(mktemp)
mise_upgrade() {
  mise upgrade --global "$@" 2>&1 | tee -a "$mise_log"
  return ${pipestatus[1]}
}

# 1. Homebrew update & upgrade & cleanup
echo "==> Updating Homebrew packages..."
run_step "brew update" brew update
run_step "brew upgrade" brew upgrade
echo "==> Cleaning up Homebrew cache..."
run_step "brew cleanup" brew cleanup -s

# 2. mise のツール（グローバルの設定のもの）を上げる。公開から 24 時間経っていない版は mise の minimum_release_age が外す
echo "==> Upgrading mise tools..."
# Node.js の最新版がセキュリティリリースで、まだ入っていないときは 24 時間待たずに上げる
node_security=$(curl -fsS https://nodejs.org/dist/index.json | jq -r '.[0] | select(.security) | .version' 2>/dev/null)
if [[ -n "$node_security" ]] && ! mise where "node@${node_security#v}" >/dev/null 2>&1; then
  echo "==> Node.js $node_security is a security release; upgrading node without minimum_release_age"
  run_step "mise upgrade node" mise_upgrade --minimum-release-age 0s node
fi
run_step "mise upgrade" mise_upgrade

# 3. Chromium / Electron の一時クローン削除 (今回の最大原因を毎日リセット)
echo "==> Cleaning up Chromium/Electron code_sign_clone temporary files..."
rm -rf /private/var/folders/*/*/*/*.code_sign_clone 2>/dev/null || true

# 4. Docker のビルドキャッシュ & 未使用イメージ削除 (起動中のみ安全に実行)
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "==> Cleaning up Docker builder cache and dangling images..."
  docker builder prune -f >/dev/null 2>&1 || true
  docker image prune -f >/dev/null 2>&1 || true
fi

# 5. ディスク空き容量チェック & 低下時のデスクトップ通知
avail_gb=$(df -g /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $4}')
echo "==> Current available storage: ${avail_gb}GB"

if [ -n "$avail_gb" ] && [ "$avail_gb" -lt 30 ]; then
  echo "==> Warning: Low disk space! (${avail_gb}GB)"
  osascript -e "display notification \"ディスク空き容量が残り ${avail_gb}GB です。整理を検討してください。\" with title \"ストレージ警告\"" 2>/dev/null || true
fi

# 6. 要約。ログを全部読まなくても、失敗した手順と見送った版が分かるようにする
held_back=$(grep -c 'ignored by minimum_release_age' "$mise_log")
rm -f "$mise_log"
echo "==> Summary: failed=[${(j:, :)failed}] mise_held_back=${held_back}"

if (( ${#failed} )); then
  osascript -e "display notification \"失敗: ${(j:, :)failed}（/tmp/brewupdate.err を確認）\" with title \"自動更新の失敗\"" 2>/dev/null || true
  echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Finished with failures ==="
else
  echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Finished successfully ==="
fi
