# dotfiles
自分用の macOS (Apple Silicon) 向けドットファイル。

## 概要
- `.macos` に Xcode Command Line Tools の導入、Homebrew インストール、`brew bundle`、macOS defaults、chezmoi による dotfiles 適用処理をまとめてあり、新規マシンの初期化を 1 コマンドで再現できます。
- 設定ファイルは [chezmoi](https://www.chezmoi.io/) で管理しており、`dot_config/` や `dot_zshenv` から `$HOME` へ展開されます。
- 会社の情報や秘密設定（社内 Git 設定、社内環境変数など）は chezmoi 内蔵の **[age](https://age-encryption.org/)** により暗号化されてリポジトリに保存されます。
- `Brewfile` で CLI / GUI ツールを宣言的に管理し、アップデートや別マシンへの展開時も同一バージョンを担保できます。

## 前提条件
- macOS (Apple Silicon)。Homebrew パスや `.macos` の手順は `arm64` を前提にしています。
- Git とネットワークアクセス
- `.macos` 内で `gh` (GitHub CLI) を利用するため、GitHub への SSH/HTTPS 認証を済ませておくとスムーズ

## セットアップ手順
```sh
git clone https://github.com/akameco/dotfiles.git ~/dev/github.com/akameco/dotfiles
cd ~/dev/github.com/akameco/dotfiles

# 1) 自動化スクリプトを実行（Homebrew、chezmoi、defaults 等を一括適用）
./.macos

# 2) 暗号化ファイル（会社設定など）を利用する場合
# パスワードマネージャー等から ~/.config/chezmoi/key.txt に age 秘密鍵を配置して再適用
chezmoi apply
```

- `.macos` は **sudo パスワードを要求し、Homebrew や GUI アプリをインストールし、macOS の各種 defaults を書き換える**。毎回中身を眺めてから実行すること。
- 一部処理で `gh repo clone akameco/dotfiles` を叩くので GitHub の認証準備は済ませておく。`gh` が不要なら適宜コメントアウト。

### `.macos` が行う主な処理
1. Xcode Command Line Tools の有無を確認し、未導入ならインストール
2. Homebrew の有無を確認し、未導入ならインストール
3. `chezmoi`, `git`, `gh` を Homebrew でインストール
4. `~/dev/github.com/akameco/dotfiles` へリポジトリをクローン (未取得の場合のみ)
5. `chezmoi apply` を実行
   - dotfiles（`dot_zshenv`, `dot_config/`）の展開
   - `.chezmoiscripts/run_onchange_after_10_brew-bundle.sh.tmpl` による `brew bundle` の自動実行
   - `.chezmoiscripts/run_once_after_00_macos-defaults.sh.tmpl` による macOS defaults（Finder, Dock, キーリピート等）の一度きり適用

## ディレクトリ構成
| パス | 役割 |
| --- | --- |
| `.macos` | 新規マシン用の最小ブートストラップスクリプト (Xcode CLT / Homebrew / chezmoi 導入) |
| `Brewfile` | 使用する CLI / GUI アプリの一覧 |
| `.chezmoiscripts/` | chezmoi スクリプト（macOS defaults 設定の一度きり適用、Brewfile 変更時の `brew bundle` 自動同期） |
| `dot_config/` | アプリ／ツールごとの設定群 (例: `dot_config/zsh`, `dot_config/nvim`) |
| `dot_gitconfig` | グローバル Git 設定（`includeIf` で会社設定を自動切替） |
| `dot_zshenv` | ZDOTDIR を `~/.config/zsh` に切り替えるためのシェルエントリ |
| `.chezmoi.toml.tmpl` | chezmoi の設定テンプレート（age 暗号化の受信者キー等） |
| `.chezmoiignore` | リポジトリ管理用ファイルをホームに展開しないための除外ルール |

## 秘密情報の暗号化管理 (age)
会社の Git 設定や環境変数などの機密情報は、chezmoi 内蔵の **age** 暗号化機能で保護されています。

### 鍵の管理
- 秘密鍵: `~/.config/chezmoi/key.txt`（**絶対にコミットしないこと**。パスワードマネージャーにバックアップ）
- 公開鍵（Recipient）: `.chezmoi.toml.tmpl` に設定

### 暗号化ファイルの編集
暗号化されたファイル（`encrypted_*`）を編集する際は、直接ファイルを開かず `chezmoi edit` を使用します。自動的に一時復号されてエディタが開き、保存終了時に自動で再暗号化されます:

```sh
# 会社用 Git 設定の編集
chezmoi edit ~/.config/git/config.work

# 会社用環境変数の編集
chezmoi edit ~/.config/zsh/work.zsh

# 差分確認と反映
chezmoi diff
chezmoi apply
```

## Brewfile の更新
手元の Homebrew 環境をリポジトリに反映する際は以下を実行してください:

```sh
brew upgrade
brew bundle dump -f --file Brewfile
```

`--file Brewfile` を付与するとリポジトリ直下のファイルが更新されるため、忘れずにコミットします。
Homebrew の更新を待たずに吐き出したい場合は `HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump -f --file Brewfile` としても OK です。

### 定期メンテナンス例
```sh
# パッケージを最新化して Brewfile に反映し、不要パッケージを洗い出す
brew upgrade
brew bundle dump -f --file Brewfile
brew bundle cleanup --force   # 削除するものがあるか確認した上で実行
```

## メンテナンスとアップデート
- **Brewfile の同期**: 新規に入れたパッケージは上記 `brew bundle dump` で追記し、不要になったものは `brew bundle cleanup` で整理します。
- **macOS defaults の追従**: OS アップデートでキーが変わった場合は `.macos` を編集し、コメントで出典をメモしておくと後で助かります。
- **Zsh 設定**: `.zshenv` で `ZDOTDIR` を `~/.config/zsh` に切り替えているため、`config/zsh/` 以下を書き換えれば次のシェル起動で反映されます。関数は `config/zsh/functions.zsh` に集約しています。
- **Neovim 設定**: `config/nvim/init.lua` が本体で、`lua/` 以下にオプション・キーマップ・プラグイン定義を分割。
- **Git コミットテンプレ**: `config/git/gitmessage` がコミット作成時にテンプレートとして開くよう、`.macos` が `git config --global commit.template ~/.config/git/gitmessage` を自動設定します。必要に応じてこのファイルを編集してください。
- **Git フック**: `.macos` で `core.hooksPath ~/.config/git/hooks` を設定します。`post-merge`/`post-rewrite` で `gwc` (gwt-clean-merged) を自動実行し、基準ブランチにマージ済み worktree をクリーンアップします。zsh が無い環境では自動スキップ。

## トラブルシューティング
- `.macos` 実行中に `xcode-select: note: install requested for command line developer tools` が出て進まない → ポップアップでインストール完了後、ターミナルに戻って Enter を押してください。
- `gh repo clone` が失敗する → GitHub CLI で `gh auth login` 済みかと SSH 鍵設定を確認し、必要なら `.macos` の `gh repo clone` を別コマンドに書き換えてから再実行してください。
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
| `cloudflared` | Cloudflare Tunnel クライアント | [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) |
| `oven-sh/bun/bun` | Bun ランタイムとパッケージマネージャ | [oven-sh/bun](https://github.com/oven-sh/bun) |
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
| `figma` | UI デザインツール | - |
| `ghostty` | GPU レンダリングに対応した高速ターミナルエミュレータ | [mitchellh/ghostty](https://github.com/mitchellh/ghostty) |
| `google-japanese-ime` | Google 日本語入力。辞書や変換精度を重視した IME | - |
| `karabiner-elements` | 修飾キー入れ替えや多段マクロが可能なキーボードリマッパ | [pqrs-org/Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) |
| `raycast` | Spotlight 代替のランチャー。スクリプト拡張やワークフロー集約向け | [raycast/extensions](https://github.com/raycast/extensions) |
| `slack` | チームコミュニケーションクライアント | - |
| `visual-studio-code` | VS Code 本体 | [microsoft/vscode](https://github.com/microsoft/vscode) |
| `vanilla` | メニューバーアイコンの表示/非表示を整理するユーティリティ | - |

## ライセンス
MIT
