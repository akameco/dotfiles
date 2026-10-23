#!/bin/zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Homebrew update & storage cleanup start ==="

# 1. Homebrew update & upgrade & cleanup
echo "==> Updating Homebrew packages..."
brew update && brew upgrade
echo "==> Cleaning up Homebrew cache..."
brew cleanup -s

# 2. mise のツール（グローバルの設定のもの）を上げる。公開から 24 時間経っていない版は mise の minimum_release_age が外す
echo "==> Upgrading mise tools..."
# Node.js の最新版がセキュリティリリースのときは 24 時間待たずに上げる
if curl -fsS https://nodejs.org/dist/index.json | jq -e '.[0].security' >/dev/null 2>&1; then
  echo "==> Latest Node.js is a security release; upgrading node without minimum_release_age"
  mise upgrade --global --minimum-release-age 0s node || echo "==> mise upgrade node failed (continuing)"
fi
mise upgrade --global || echo "==> mise upgrade failed (continuing)"

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

echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Finished successfully ==="
