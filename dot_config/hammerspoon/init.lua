-- -----------------------------------------------------------------------------
-- Hammerspoon Configuration
-- -----------------------------------------------------------------------------

-- 設定ファイル変更時の自動リロード
local function reloadConfig(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end

-- ~/.config/hammerspoon 配下の Lua ファイル変更を監視
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon", reloadConfig)
configWatcher:start()

-- コマンドラインツール `hs` のインストール・有効化
if hs.ipc then
  hs.ipc.cliInstall()
end

-- 起動・リロード完了通知
hs.alert.show("🔨 Hammerspoon loaded")
