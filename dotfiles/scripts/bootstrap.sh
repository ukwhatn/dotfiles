#!/bin/bash
set -euo pipefail

# 新マシン初期セットアップ（bash版）
# Homebrew → dotfiles clone → Brewfile → fish切り替えまで
#
# 使い方:
#   bash <(curl -fsSL https://raw.githubusercontent.com/ukwhatn/dotfiles/refs/heads/main/dotfiles/scripts/bootstrap.sh)
#   または: bash bootstrap.sh [remote_url]

REMOTE_URL="${1:-git@github.com:ukwhatn/dotfiles.git}"
DOTFILES_GIT="$HOME/.dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

dotfiles() {
    git --git-dir="$DOTFILES_GIT" --work-tree="$HOME" "$@"
}

echo "=== 新マシンセットアップ開始 ==="
echo ""

# --------------------------------------------------------
# 1. Xcode Command Line Tools
# --------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
    echo "[1/8] Xcode Command Line Tools をインストール中..."
    xcode-select --install
    echo "インストール完了後、このスクリプトを再実行してください。"
    exit 0
else
    echo "[1/8] Xcode Command Line Tools: インストール済み"
fi

# --------------------------------------------------------
# 2. Homebrew
# --------------------------------------------------------
# PATHに /opt/homebrew/bin がない新規シェルでも検出できるようにする
if [ -x /opt/homebrew/bin/brew ]; then
    echo "[2/8] Homebrew: インストール済み"
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew &>/dev/null; then
    echo "[2/8] Homebrew: インストール済み"
else
    echo "[2/8] Homebrew をインストール中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --------------------------------------------------------
# 3. git + fish（dotfiles clone に最低限必要）
# --------------------------------------------------------
echo "[3/8] git, fish をインストール中..."
brew install git fish

# --------------------------------------------------------
# 4. dotfiles clone & checkout
# --------------------------------------------------------
echo "[4/8] dotfiles をセットアップ中..."
mkdir -p "$BACKUP_DIR"

if [ -d "$DOTFILES_GIT" ]; then
    echo "  既存の .dotfiles.git を検出。バックアップして再クローンします。"
    mv "$DOTFILES_GIT" "$BACKUP_DIR/.dotfiles.git.bak"
fi

git clone --bare "$REMOTE_URL" "$DOTFILES_GIT"
dotfiles config status.showUntrackedFiles no
dotfiles config init.defaultBranch main

# .ssh を退避（SSH鍵がないとsubmodule cloneできないため保護する）
SSH_SAVED=""
if [ -d "$HOME/.ssh" ] && [ ! -f "$HOME/.ssh/.git" ]; then
    echo "  .ssh を保護（submodule clone に必要な SSH 鍵を維持）..."
    cp -a "$HOME/.ssh" "$BACKUP_DIR/.ssh-preserve"
    SSH_SAVED=1
fi

# 管理対象ファイルの一覧を取得し、.ssh以外の既存ファイルを削除して強制checkout
echo "  管理対象ファイルを展開中（.ssh 以外は強制上書き）..."
tracked_files=$(dotfiles ls-tree -r --name-only HEAD 2>/dev/null) || true
for f in $tracked_files; do
    # .ssh 配下はスキップ
    case "$f" in .ssh|.ssh/*) continue ;; esac
    if [ -e "$HOME/$f" ]; then
        rm -rf "$HOME/$f"
    fi
done
# submodule ディレクトリも .ssh 以外を削除
if [ -f "$HOME/.gitmodules" ]; then
    rm -f "$HOME/.gitmodules"
fi
dotfiles checkout --force
echo "  checkout 完了"

# .ssh を復元
if [ -n "$SSH_SAVED" ]; then
    rm -rf "$HOME/.ssh" 2>/dev/null || true
    mv "$BACKUP_DIR/.ssh-preserve" "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
    echo "  .ssh を復元しました"
fi

# submodule: .ssh 以外を初期化
echo "  submodule 用の既存ディレクトリをクリーンアップ中..."
if [ -f "$HOME/.gitmodules" ]; then
    subpaths=$(git config -f "$HOME/.gitmodules" --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}') || true
    for subpath in $subpaths; do
        case "$subpath" in .ssh) continue ;; esac
        rm -rf "$HOME/$subpath" 2>/dev/null || true
    done
fi

# submodule（.ssh 以外を初期化）
echo "  submodule を初期化中（.ssh は手動配置済みのためスキップ）..."
if [ -f "$HOME/.gitmodules" ]; then
    subpaths=$(git config -f "$HOME/.gitmodules" --get-regexp 'submodule\..*\.path' 2>/dev/null | awk '{print $2}') || true
    for subpath in $subpaths; do
        if [ "$subpath" = ".ssh" ]; then
            echo "    スキップ: .ssh（手動配置済み）"
            continue
        fi
        dotfiles submodule update --init --recursive -- "$subpath" || echo "    警告: $subpath の初期化に失敗"
    done
fi
echo "  submodule 初期化完了"

# --------------------------------------------------------
# 5. Brewfile でアプリ一括インストール
# --------------------------------------------------------
echo "[5/8] Brewfile からアプリをインストール中..."
if [ -f "$HOME/Brewfile" ]; then
    brew bundle --file="$HOME/Brewfile" || true
    echo "  Brewfile インストール完了（一部失敗はスキップ済み）"
else
    echo "  警告: ~/Brewfile が見つかりません。スキップします。"
fi

# --------------------------------------------------------
# 6. fish plugin (fisher)
# --------------------------------------------------------
echo "[6/8] fish plugin をインストール中..."
if [ -f "$HOME/.config/fish/fish_plugins" ]; then
    fish -c '
        if not functions -q fisher
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher install jorgebucaran/fisher
        end
        fisher update
    '
    echo "  fisher + plugins インストール完了"
else
    echo "  fish_plugins が見つかりません。スキップします。"
fi

# --------------------------------------------------------
# 7. 開発環境 (mise, uv, bun)
# --------------------------------------------------------
echo "[7/8] 開発環境をセットアップ中..."

# mise: Brewfile でインストール済み → activate + install
if command -v mise &>/dev/null; then
    echo "  mise: ツールチェインをインストール中..."
    if [ -f "$HOME/.config/mise/config.toml" ]; then
        mise install --yes
        echo "  mise install 完了"
    else
        echo "  mise config.toml が見つかりません。スキップします。"
    fi
else
    echo "  警告: mise が見つかりません"
fi

# uv: Brewfile でインストール済み
if command -v uv &>/dev/null; then
    echo "  uv: インストール済み ($(uv --version))"
else
    echo "  警告: uv が見つかりません"
fi

# bun: brew にないため独自インストーラを使用
if ! command -v bun &>/dev/null; then
    echo "  bun: インストール中..."
    curl -fsSL https://bun.sh/install | bash
    echo "  bun インストール完了"
else
    echo "  bun: インストール済み ($(bun --version))"
fi

# --------------------------------------------------------
# 8. tmux plugin manager (TPM)
# --------------------------------------------------------
echo "[8/8] tmux plugin をセットアップ中..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "  TPM インストール完了"
    echo "  tmux起動後に prefix + I でプラグインをインストールしてください"
else
    echo "  TPM: インストール済み"
fi

# --------------------------------------------------------
# 完了
# --------------------------------------------------------
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "バックアップ先: $BACKUP_DIR"
echo ""
echo "残りの手動作業:"
echo "  1. デフォルトシェルを fish に変更:"
echo "     echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells"
echo "     chsh -s /opt/homebrew/bin/fish"
echo "  2. tmux を起動して prefix + I でプラグインインストール"
echo "  3. Mac App Store にログイン後: mas install で MAS アプリをインストール"
echo "     (Brewfile の mas 行は Apple ID ログインが必要)"
echo "  4. 各アプリの初期設定（1Password, Google Chrome 等）"
echo ""
echo "確認コマンド:"
echo "  dotfiles status"
echo "  dotfiles submodule status"
echo "  brew bundle check --file=~/Brewfile"
