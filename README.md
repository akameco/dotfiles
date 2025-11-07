# dotfiles
> akameco の macOS 向けドットファイル／セットアップスクリプト集

## 概要
- `.macos` ひとつで Xcode Command Line Tools の導入から Homebrew/Brewfile、macOS defaults の適用、シンボリックリンク作成まで自動化
- `config/` 以下に Raycast や Karabiner などアプリ単位の設定を整理し、必要なものだけリンクして再利用可能
- `Brewfile` で CLI / GUI ツールを一括管理し、環境の再現性を担保

## 前提条件
- macOS (Apple Silicon / Intel)
- Git とネットワークアクセス
- `hub` コマンドを利用するため GitHub 認証が済んでいるとスムーズ

## セットアップ
```sh
git clone https://github.com/akameco/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# セットアップ内容を確認した上で実行
./.macos
```

### `.macos` で行う主な処理
1. System Settings を閉じ、Xcode Command Line Tools を確認・インストール
2. `sudo` セッションを維持しつつ Homebrew / hub / git などを導入
3. `~/dev/github.com/akameco/dotfiles` にリポジトリをクローン (未取得の場合)
4. `brew bundle --global` でパッケージを一括適用
5. `.zshenv` や `config` ディレクトリをホームディレクトリへシンボリックリンク
6. `defaults write` で Finder / Dock / 入力設定など macOS の既定値を一括変更し、関連プロセスを再起動

スクリプトの最後で Finder / Dock / SystemUIServer を再起動するため、適用直後に UI が一瞬リフレッシュされます。

## ディレクトリ構成
| パス | 役割 |
| --- | --- |
| `.macos` | macOS 初期設定および Homebrew セットアップスクリプト |
| `Brewfile` | 使用する CLI / GUI アプリの一覧 |
| `config/` | アプリ／ツールごとの設定群 (例: `config/zsh`, `config/raycast`) |
| `.zshenv` | ZDOTDIR を `~/.config/zsh` に切り替えるためのシェルエントリ |

`config` 内で追加したい dotfile があれば、`.macos` 内の `ln -s` セクションに追記すると次回以降の実行で自動リンクされます。

## Brewfile の更新
手元の Homebrew 環境をリポジトリに反映する際は以下を実行してください:

```sh
brew upgrade
brew bundle dump -f --file Brewfile
```

`--file Brewfile` を付与するとリポジトリ直下のファイルが更新されるため、忘れずにコミットします。

## ライセンス
MIT
