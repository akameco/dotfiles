# dotfiles
自分用の macOS (Apple Silicon) 向けドットファイル。

## 概要
- `.macos` に Xcode Command Line Tools の導入、Homebrew インストール、`brew bundle`、macOS defaults、dotfiles のリンク処理をまとめてあり、新規マシンの初期化を 1 コマンドで再現できます。
- Zsh や Git、Raycast、Karabiner などの設定は `config/` 以下にアプリ単位で格納しているので、必要なものだけリンクして使い回せます。
- `Brewfile` で CLI / GUI ツールを宣言的に管理し、アップデートや別マシンへの展開時も同一バージョンを担保できます。

## 前提条件
- macOS (Apple Silicon)。Homebrew パスや `.macos` の手順は `arm64` を前提にしています。
- Git とネットワークアクセス
- `.macos` 内で `hub` を利用するため、GitHub への SSH/HTTPS 認証を済ませておくとスムーズ

## セットアップ手順
```sh
git clone https://github.com/akameco/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 1) 必要な設定をリンク（例）
ln -sf ~/.dotfiles/.zshenv ~/.zshenv
ln -sF ~/.dotfiles/config ~/.config

# 2) 自動化スクリプトを実行（内容を確認してから）
./.macos
```

- `.macos` は **sudo パスワードを要求し、Homebrew や GUI アプリをインストールし、macOS の各種 defaults を書き換える**。毎回中身を眺めてから実行すること。
- 一部処理で `hub clone akameco/dotfiles` を叩くので GitHub の認証準備は済ませておく。`hub` が不要なら適宜コメントアウト。

### `.macos` が行う主な処理
1. System Settings を終了し、Xcode Command Line Tools の有無を確認（無い場合は `xcode-select --install` を起動し完了待ち）
2. `sudo -v` と keep-alive で管理者権限を維持したまま Homebrew/hub/git をセットアップ
3. `~/dev/github.com/akameco/dotfiles` へリポジトリをクローン (未取得の場合のみ)
4. `brew bundle --global` で CLI / GUI パッケージをまとめて適用
5. `.zshenv` と `config/` ディレクトリをホームディレクトリにシンボリックリンク
6. Finder / Dock / 入力設定などの macOS defaults を `defaults write` で一括変更し、Finder / Dock / SystemUIServer を再起動

> メモ: まとめて走らせたくないときは上記ステップを個別に実行する。

## ディレクトリ構成
| パス | 役割 |
| --- | --- |
| `.macos` | macOS 初期設定および Homebrew セットアップスクリプト |
| `Brewfile` | 使用する CLI / GUI アプリの一覧 |
| `config/` | アプリ／ツールごとの設定群 (例: `config/zsh`, `config/nvim`, `config/raycast`) |
| `.zshenv` | ZDOTDIR を `~/.config/zsh` に切り替えるためのシェルエントリ |

`config` にファイルを追加した場合は、`.macos` の「シンボリックリンク」セクションへ追記しておくと次回実行時に自動的にリンクされます。

## Brewfile の更新
手元の Homebrew 環境をリポジトリに反映する際は以下を実行してください:

```sh
brew upgrade
brew bundle dump -f --file Brewfile
```

`--file Brewfile` を付与するとリポジトリ直下のファイルが更新されるため、忘れずにコミットします。

## メンテナンスとアップデート
- **Brewfile の同期**: 新規に入れたパッケージは上記 `brew bundle dump` で追記し、不要になったものは `brew bundle cleanup` で整理します。
- **macOS defaults の追従**: OS アップデートでキーが変わった場合は `.macos` を編集し、コメントで出典をメモしておくと後で助かります。
- **Zsh 設定**: `.zshenv` で `ZDOTDIR` を `~/.config/zsh` に切り替えているため、`config/zsh/` 以下を書き換えれば次のシェル起動で反映されます。関数は `config/zsh/functions.zsh` に集約しています。
- **Neovim 設定**: `config/nvim/init.lua` が本体で、`lua/` 以下にオプション・キーマップ・プラグイン定義を分割。

## トラブルシューティング
- `.macos` 実行中に `xcode-select: note: install requested for command line developer tools` が出て進まない → ポップアップでインストール完了後、ターミナルに戻って Enter を押してください。
- `hub clone` が失敗する → GitHub アカウントの SSH 鍵が設定済みか確認し、必要なら `.macos` の `hub clone` を好きなコマンドに書き換えてから再実行してください。
- GUI アプリのインストールが終わったのに Dock に表示されない → `killall Dock` をもう一度実行すると最新状態に更新されます。

## Neovim 利用メモ
- `nvim` 初回起動時に `lazy.nvim` が自動クローンされる。`:Lazy sync` を一度叩けば Telescope / Oil / Devicons だけ入る。
- `<leader>f` 系が Unite 代替。`fm`=MRU、`ff`=カレント dir、`fp`=Git ルート、`fs`=カーソル語 grep、`fg`=live grep など。
- VimFiler 代替は `oil.nvim`。`,vf` でバッファディレクトリをフロート表示、`<leader>e` で左ペイン。中では `h`/`l` で移動。
- LSP/補完は入れていない（コード作業は VS Code 前提）。必要になったら `config/nvim/lua/plugins/init.lua` に追記する。
- Git の差分・ブレームは `gitsigns.nvim` に任せている（行頭に記号、`current_line_blame` あり）。

## Brewfile 収録ツール
### CLI ツール (brew)
| 名前 | 用途 | GitHub |
| --- | --- | --- |
| `bat` | `cat` 互換のシンタックスハイライト付きビューア | [sharkdp/bat](https://github.com/sharkdp/bat) |
| `eza` | `ls` 互換のモダンなファイルリスト表示 | [eza-community/eza](https://github.com/eza-community/eza) |
| `fzf` | シェルで使える汎用ファジーファインダ | [junegunn/fzf](https://github.com/junegunn/fzf) |
| `gawk` | GNU awk。テキスト処理や集計用の AWK 実装 | - |
| `gh` | GitHub CLI。Issue/PR 操作や Actions 実行をターミナルから行う | [cli/cli](https://github.com/cli/cli) |
| `ghq` | Git リポジトリを規則的なディレクトリに集約管理するツール | [x-motemen/ghq](https://github.com/x-motemen/ghq) |
| `git` | バージョン管理システム。CLI での基本操作を担う | [git/git](https://github.com/git/git) |
| `jq` | JSON の抽出や変形を行うフィルタ | [jqlang/jq](https://github.com/jqlang/jq) |
| `mise` | Node/Python など複数ランタイムを管理できるバージョンマネージャ | [jdx/mise](https://github.com/jdx/mise) |
| `starship` | 高機能かつ高速なクロスシェルプロンプト | [starship/starship](https://github.com/starship/starship) |
| `tig` | Git 履歴を対話的に参照する TUI クライアント | [jonas/tig](https://github.com/jonas/tig) |
| `neovim` | Vim 互換のモダンなターミナルエディタ。Lua ベースで設定拡張が容易 | [neovim/neovim](https://github.com/neovim/neovim) |
| `zoxide` | 頻繁に使うディレクトリへ学習ベースでジャンプできる `cd` 代替 | [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |

### GUI / バックグラウンドアプリ (cask)
| 名前 | 用途 | GitHub |
| --- | --- | --- |
| `bettertouchtool` | トラックパッド・キーボード・マウスジェスチャの高度なカスタマイズ | - |
| `claude-code` | Claude Code クライアント。AI ペアプロやコード生成をデスクトップで利用 | - |
| `codex` | Codex CLI のデスクトップアプリ。ローカル開発補助エージェントとの連携用 | - |
| `ghostty` | GPU レンダリングに対応した高速ターミナルエミュレータ | [mitchellh/ghostty](https://github.com/mitchellh/ghostty) |
| `google-japanese-ime` | Google 日本語入力。辞書や変換精度を重視した IME | - |
| `karabiner-elements` | 修飾キー入れ替えや多段マクロが可能なキーボードリマッパ | [pqrs-org/Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) |
| `raycast` | Spotlight 代替のランチャー。スクリプト拡張やワークフロー集約向け | [raycast/extensions](https://github.com/raycast/extensions) |
| `slack` | チームコミュニケーションクライアント | - |
| `vanilla` | メニューバーアイコンの表示/非表示を整理するユーティリティ | - |

## ライセンス
MIT
