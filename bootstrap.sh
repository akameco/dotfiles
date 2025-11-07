#!/usr/bin/env bash
set -euo pipefail


DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/backup-dotfiles-$(date +%Y%m%d-%H%M%S)"


step() { printf "\n\033[1;36m▶ %s\033[0m\n" "$1"; }
info() { printf " \033[0;32m- %s\033[0m\n" "$1"; }
warn() { printf " \033[0;33m! %s\033[0m\n" "$1"; }


step "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  read -rp "インストール完了後にEnterを押してください…"
fi


step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi


# Apple Silicon のパスを確実に通す
if [[ -d "/opt/homebrew/bin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


step "Brewfile インストール"
brew update
brew bundle --file="$DOTFILES_DIR/Brewfile"


step "既存ファイルのバックアップとシンボリックリンク"
backup_and_link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR"/
    warn "バックアップ: $dst -> $BACKUP_DIR/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  info "link: $dst → $src"
}


backup_and_link "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/shell/.zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
backup_and_link "$DOTFILES_DIR/editor/.editorconfig" "$HOME/.editorconfig"


step "macOS 既定値の適用（任意）"
read -rp "macOS 調整を適用しますか？ [y/N]: " yn
if [[ "${yn:-n}" =~ ^[Yy]$ ]]; then
  bash "$DOTFILES_DIR/macos.sh"
fi


step "完了"
info "新しいシェルで反映: exec zsh -l"
