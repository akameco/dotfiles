# dotfiles
自分用の macOS (Apple Silicon) 向けドットファイル。

## 概要
- ブートストラップスクリプト `.macos` と [chezmoi](https://www.chezmoi.io/) により、新規マシンの環境構築（Xcode CLT、Homebrew、dotfiles 展開、macOS defaults 適用、Brewfile 同期）を自動化できます。
- 設定ファイルは chezmoi で管理しており、`dot_config/` や `dot_zshenv`、`Library/LaunchAgents/` などから `$HOME` へ展開されます。
- 機密情報（会社用の Git 設定や環境変数、Finicky の振り分けルールなど）は chezmoi 内蔵の **[age](https://age-encryption.org/)** で暗号化してリポジトリに保存されます。
- `Brewfile` で CLI / GUI ツール / VS Code 拡張を宣言的に管理。chezmoi スクリプトにより、Brewfile 変更時にも自動で `brew bundle` が同期されます。
- LaunchAgent により毎朝 8:30 に Homebrew パッケージ（`brew update && brew upgrade`）を自動更新します。
- Git Worktree と PR を fzf で快適に操作するシェル関数群や、Ghostty ステータスバー連携を内蔵しています。

## 前提条件
- macOS (Apple Silicon / `arm64`)
- Git とネットワークアクセス
- GitHub へのアクセス（`.macos` 内で `gh repo clone` を行うため）

## セットアップ手順

### 1. 新規マシンでの初期セットアップ
```sh
# リポジトリをクローンして初期化スクリプトを実行
git clone https://github.com/akameco/dotfiles.git ~/dev/github.com/akameco/dotfiles
cd ~/dev/github.com/akameco/dotfiles

# Homebrew、chezmoi、dotfiles 展開、macOS defaults、brew bundle を一括適用
./.macos
```

> [!NOTE]
> `.macos` は sudo パスワードを要求し、各種ツールや GUI アプリのインストール、macOS defaults の設定変更を行います。

#### `.macos` が行う主な処理
1. **Xcode Command Line Tools** の有無を確認し、未導入ならインストール
2. **Homebrew** の有無を確認し、未導入ならインストール
3. **chezmoi**, **git**, **gh** を Homebrew でインストール
4. `~/dev/github.com/akameco/dotfiles` へのクローン（未取得時のみ）
5. `~/.local/share/chezmoi` へソースディレクトリのシンボリックリンクを作成
6. `chezmoi apply` を実行:
   - dotfiles（`~/.zshenv`, `~/.config/`, `~/Library/LaunchAgents/` 等）の展開
   - `.chezmoiscripts/run_once_after_00_macos-defaults.sh.tmpl` による macOS defaults 設定（Finder, Dock, キーリピート等）の一度きり適用
   - `.chezmoiscripts/run_onchange_after_10_brew-bundle.sh.tmpl` による `brew bundle` の自動実行

### 2. 暗号化ファイル（会社設定など）の復号
age 秘密鍵を配置して再適用します：
```sh
# パスワードマネージャー等から key.txt を配置
mkdir -p ~/.config/chezmoi
# ~/.config/chezmoi/key.txt に秘密鍵を保存

# 設定を再適用（暗号化ファイルが復号されて配置される）
chezmoi apply
```

### 3. 自動更新 LaunchAgent のロード（任意）
毎日 8:30 に Homebrew を自動更新する LaunchAgent を有効化します：
```sh
launchctl load ~/Library/LaunchAgents/com.akameco.brewupdate.plist
```

## ディレクトリ構成
| パス | 役割 |
| --- | --- |
| `.macos` | 新規マシン用の最小ブートストラップスクリプト (Xcode CLT / Homebrew / chezmoi 導入) |
| `Brewfile` | 使用する CLI / GUI アプリ / VS Code 拡張の一覧 |
| `.chezmoiscripts/` | chezmoi スクリプト（macOS defaults 設定の一度きり適用、Brewfile 変更時の `brew bundle` 自動同期） |
| `Library/LaunchAgents/` | 定期実行 LaunchAgent（Homebrew 自動更新用 `com.akameco.brewupdate.plist`） |
| `dot_config/` | アプリ／ツールごとの設定群 |
| ├ `bat/` | `bat` 設定 |
| ├ `finicky/` | Finicky 設定（`encrypted_dot_finicky.js.age` で暗号化管理） |
| ├ `gh/` | GitHub CLI 設定 (`private_config.yml`, `private_hosts.yml`) |
| ├ `ghostty/` | Ghostty ターミナル設定 |
| ├ `git/` | Git 設定（テンプレート、フック、グローバル ignore） |
| ├ `karabiner/` | Karabiner-Elements 設定（SpaceFn、Esc/英数切り替えなど） |
| ├ `launchd/` | 定期実行スクリプト（Homebrew アップデート用の `homebrew-update.sh`） |
| ├ `mise/` | ランタイム管理設定（Node.js, pnpm, Vercel CLI） |
| ├ `nvim/` | Neovim 設定（lazy.nvim, telescope, oil.nvim, gitsigns, tokyonight） |
| └ `zsh/` | Zsh 設定（`.zshrc`、`functions.zsh`、暗号化された会社用環境変数 `encrypted_work.zsh.age`） |
| `dot_gitconfig` | グローバル Git 設定（ユーザー情報、エイリアス、テンプレート・フック設定） |
| `dot_zshenv` | ZDOTDIR を `~/.config/zsh` に切り替えるためのシェルエントリ |
| `symlink_dot_finicky.js` | `~/.finicky.js` を `~/.config/finicky/.finicky.js` にリンクする定義 |
| `.chezmoi.toml.tmpl` | chezmoi の設定テンプレート（age 暗号化の受信者キー等） |
| `.chezmoiignore` | リポジトリ管理用ファイルをホームに展開しないための除外ルール |

## 秘密情報の暗号化管理 (age)
環境変数や Finicky のドメイン振り分け設定などの機密情報は、chezmoi 内蔵の **age** 暗号化機能で保護されています。

### 鍵の管理
- 秘密鍵: `~/.config/chezmoi/key.txt`（**絶対にコミットしないこと**。パスワードマネージャーにバックアップ）
- 公開鍵（Recipient）: `.chezmoi.toml.tmpl` に設定

### 暗号化ファイルの編集
暗号化されたファイル（`encrypted_*`）を編集する際は、直接ファイルを開かず `chezmoi edit` を使用します。自動的に一時復号されてエディタが開き、保存終了時に自動で再暗号化されます:

```sh
# 会社用環境変数の編集
chezmoi edit ~/.config/zsh/work.zsh

# Finicky 設定（業務URL・プロファイル振り分け等）の編集
chezmoi edit ~/.config/finicky/.finicky.js

# 差分確認と反映
chezmoi diff
chezmoi apply
```

## Brewfile とパッケージ管理

### 手動での Brewfile 更新
手元の Homebrew 環境で追加・削除したパッケージをリポジトリへ反映する際は以下を実行します:

```sh
brew upgrade
brew bundle dump -f --file Brewfile
```

> [!TIP]
> リポジトリ内の `Brewfile` が変更された場合、chezmoi スクリプト（`.chezmoiscripts/run_onchange_after_10_brew-bundle.sh.tmpl`）がハッシュの変化を検知し、次回 `chezmoi apply` 時に自動で `brew bundle` が実行されます。

### LaunchAgent による毎朝の自動アップデート
`Library/LaunchAgents/com.akameco.brewupdate.plist` により、毎朝 8:30 にバックグラウンドで `brew update && brew upgrade` が自動実行されます。

- **実行スクリプト**: `~/.config/launchd/homebrew-update.sh`
- **ログ出力先**: `/tmp/brewupdate.out`, `/tmp/brewupdate.err`
- **ジョブの登録 / 解除**:
  ```sh
  # 有効化（登録）
  launchctl load ~/Library/LaunchAgents/com.akameco.brewupdate.plist

  # 無効化（解除）
  launchctl unload ~/Library/LaunchAgents/com.akameco.brewupdate.plist
  ```

## 開発環境とワークフロー

### 1. Git Worktree & ブランチ操作（fzf 連携）
`functions.zsh` に Git 操作を高速化するシェル関数が組み込まれています:

- **`gw` (`gwt-fzf`)**:
  - `git worktree` の一覧を fzf であいまい検索してジャンプ。
  - GitHub CLI (`gh`) と連携し、ブランチ名に対応する **PR 番号・タイトル** を一覧に同時表示。
  - ディレクトリの利用履歴（アクセス日時）を記録し、最近使った worktree が上位に並びます。
  - 実行時、前回から 24 時間以上経過していればバックグラウンドでマージ済み worktree の自動クリーンアップを実行。
- **`gwc` (`gwt-clean-merged`)**:
  - 基準ブランチ（`main` / `master` / `origin/HEAD`）にマージ済みの worktree およびローカルブランチを一括削除。
  - Git フック（`~/.config/git/hooks/post-merge`, `post-rewrite`）にも組み込まれており、マージやリベース後にも自動実行。
- **`gb` (`gb-fzf`)**:
  - ローカルブランチを fzf で選択して `git switch`。PR タイトルも併せて表示。
- **`git branch` (引数なし)**:
  - 対話シェルで `git branch` を叩くと、自動で各ブランチの PR 番号とタイトルを付与して整形表示。
- **`gho`**:
  - デフォルトブランチならリポジトリの GitHub ページを開き、トピックブランチなら該当する PR ページをブラウザで開く。

### 2. ターミナルとシェル (Ghostty, Starship, zoxide)
- **Ghostty**:
  - GPU レンダリングによる高速ターミナルエミュレータ。
  - フォントに `UDEV Gothic 35NFLG`、カラースキームに `TokyoNight` を設定。
  - 設定ファイル `dot_config/ghostty/config` は macOS defaults スクリプト実行時に `~/Library/Application Support/com.mitchellh.ghostty/config` へ自動でシンボリックリンクされます。
- **Ghostty / tmux ステータスバー連携**:
  - カレントブランチの PR タイトルを `precmd` フックで自動取得し、Ghostty のステータスバー（またはウィンドウタイトル）に常時表示。
- **Starship**: 超軽量・高速なプロンプト。
- **zoxide**: 学習型ディレクトリ移動。`Ctrl + G` で対話検索ジャンプ (`fzf-zoxide-cd`)。
- **安全な削除**: `rm` は `trash` コマンドにエイリアスされており、誤削除防止のため Finder 経由でゴミ箱へ移動（本来の `/bin/rm` は `realrm` で実行可能）。
- **AI ツールエイリアス**:
  - `ai`: `claude`
  - `gemini`: `agy` (Antigravity CLI)

### 3. ランタイム管理 (mise)
`~/.config/mise/config.toml` にて以下のツールバージョンを宣言的に管理しています:
- `node`: `lts`
- `pnpm`: `latest`
- `npm:vercel`: `latest`

### 4. キーリマップ (Karabiner-Elements)
`dot_config/karabiner/` 配下で複雑なキーリマップを定義:
- **SpaceFn**: スペースキーの長押しでカーソル移動（H/J/K/L）などのレイヤーに切り替え
- **Esc / 英数**: Esc キー押下時に自動で英数入力モードに切り替え
- **Shift + Esc**: チルダ (`~`) を入力

## Neovim 利用メモ
軽量かつ素早いコード閲覧・編集用のエディタ設定（メインの開発は VS Code 前提）。初回起動時に `lazy.nvim` が自動セットアップされます。

- **プラグイン構成**:
  - `folke/tokyonight.nvim`: カラースキーム (`tokyonight-night`)
  - `stevearc/oil.nvim`: バッファディレクトリをフロート表示 (`,vf`)。中では `h` で親ディレクトリ、`l` でファイルオープン。
  - `nvim-telescope/telescope.nvim`: ファジーファインダ
    - `<leader>fm`: 最近使ったファイル（カレントディレクトリ内）
    - `<leader>fa`: ファイル検索（全体）
    - `<leader>fp`: Git ルート配下のファイル検索
  - `lewis6991/gitsigns.nvim`: 行頭の Git 差分サイン、行末の `current_line_blame`（500ms ディレイ）
- **キーマップ・省略記法**:
  - `<D-s>` (Cmd-s): ファイル保存
  - `<leader>mm`: `~/Memo/memo.md` を開く（シェルエイリアス `m` でも可）
  - 挿入モード略記: `dd` で日付 (`YYYY-MM-DD`)、`dt` で時刻 (`HH:MM`) を入力し、`Cmd-k` または `Ctrl-k` で展開

## トラブルシューティング
- **`.macos` 実行中に `xcode-select: note: install requested...` が出て進まない**:
  - ポップアップのダイアログに従ってインストールを完了させ、ターミナルに戻って Enter を押してください。
- **`gh repo clone` が失敗する**:
  - 事前に `gh auth login` で GitHub 認証を済ませているか確認してください。
- **暗号化ファイルが復号されない**:
  - `~/.config/chezmoi/key.txt` に正しい age 秘密鍵が配置されているか確認し、`chezmoi apply` を再実行してください。
- **GUI アプリのインストール後に Dock や Finder の反映が遅い**:
  - `killall Dock` や `killall Finder` を手動実行すると即座に反映されます。

## Brewfile 収録ツール

### CLI ツール (brew)
| 名前 | 用途 | GitHub |
| --- | --- | --- |
| `bat` | `cat` 互換のシンタックスハイライト付きビューア | [sharkdp/bat](https://github.com/sharkdp/bat) |
| `chezmoi` | dotfiles 管理ツール（age 暗号化対応） | [twpayne/chezmoi](https://github.com/twpayne/chezmoi) |
| `cloudflared` | Cloudflare Tunnel クライアント | [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) |
| `eza` | `ls` 互換のモダンなファイルリスト表示 | [eza-community/eza](https://github.com/eza-community/eza) |
| `fzf` | シェルで使える汎用ファジーファインダ | [junegunn/fzf](https://github.com/junegunn/fzf) |
| `gawk` | GNU awk。テキスト処理や集計用の AWK 実装 | - |
| `gh` | GitHub CLI。Issue/PR 操作や Actions 実行をターミナルから行う | [cli/cli](https://github.com/cli/cli) |
| `ghq` | Git リポジトリを規則的なディレクトリに集約管理するツール | [x-motemen/ghq](https://github.com/x-motemen/ghq) |
| `git` | バージョン管理システム。CLI での基本操作を担う | [git/git](https://github.com/git/git) |
| `jq` | JSON の抽出や変形を行うフィルタ | [jqlang/jq](https://github.com/jqlang/jq) |
| `mise` | Node/Python など複数ランタイムを管理できるバージョンマネージャ | [jdx/mise](https://github.com/jdx/mise) |
| `neovim` | Vim 互換のモダンなターミナルエディタ。Lua ベースで設定 | [neovim/neovim](https://github.com/neovim/neovim) |
| `starship` | 高機能かつ高速なクロスシェルプロンプト | [starship/starship](https://github.com/starship/starship) |
| `tig` | Git 履歴を対話的に参照する TUI クライアント | [jonas/tig](https://github.com/jonas/tig) |
| `zoxide` | 頻繁に使うディレクトリへ学習ベースでジャンプできる `cd` 代替 | [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| `oven-sh/bun/bun` | Bun ランタイムとパッケージマネージャ | [oven-sh/bun](https://github.com/oven-sh/bun) |

### GUI / バックグラウンドアプリ (cask)
| 名前 | 用途 | GitHub |
| --- | --- | --- |
| `bettertouchtool` | トラックパッド・キーボード・マウスジェスチャの高度なカスタマイズ | - |
| `claude-code` | Claude Code デスクトップアプリ | - |
| `codex` | Codex CLI デスクトップアプリ | - |
| `figma` | UI デザインツール | - |
| `finicky` | ブラウザ・プロファイル自動振り分けユーティリティ | [johnste/finicky](https://github.com/johnste/finicky) |
| `font-udev-gothic-nf` | UDEV Gothic + Nerd Fonts プログラミング向け日本語等幅フォント | [yuru7/udev-gothic](https://github.com/yuru7/udev-gothic) |
| `ghostty` | GPU レンダリングに対応した高速ターミナルエミュレータ | [mitchellh/ghostty](https://github.com/mitchellh/ghostty) |
| `google-japanese-ime` | Google 日本語入力。辞書や変換精度を重視した IME | - |
| `karabiner-elements` | 修飾キー入れ替えや多段マクロが可能なキーボードリマッパ | [pqrs-org/Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) |
| `raycast` | Spotlight 代替のランチャー。スクリプト拡張やワークフロー集約向け | [raycast/extensions](https://github.com/raycast/extensions) |
| `slack` | チームコミュニケーションクライアント | - |
| `vanilla` | メニューバーアイコンの表示/非表示を整理するユーティリティ | - |
| `visual-studio-code` | VS Code 本体 | [microsoft/vscode](https://github.com/microsoft/vscode) |

### VS Code 拡張機能 (vscode)
Brewfile にて以下の拡張機能のインストールを宣言的に管理しています:
- **言語・フレームワーク**: Astro (`astro-vscode`), Tailwind CSS (`vscode-tailwindcss`), ESLint (`vscode-eslint`), Prettier (`prettier-vscode`), YAML (`vscode-yaml`), Svelte (`svelte-vscode`), MDX (`vscode-mdx`)
- **エディタ・ツール**: Claude Code (`claude-code`), EditorConfig (`editorconfig`), Vim (`vscodevim`), Code Spell Checker (`code-spell-checker`), Dev Containers (`vscode-containers`), Live Share (`vsliveshare`), 日本語言語パック (`vscode-language-pack-ja`)

## ライセンス
MIT

