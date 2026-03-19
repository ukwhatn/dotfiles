#!/bin/bash
set -euo pipefail

# 新マシン初期セットアップ（bash版）
# Homebrew → dotfiles clone → Brewfile → fish切り替えまで
#
# 使い方:
#   curl -fsSL <raw_url> | bash
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
    echo "[1/7] Xcode Command Line Tools をインストール中..."
    xcode-select --install
    echo "インストール完了後、このスクリプトを再実行してください。"
    exit 0
else
    echo "[1/7] Xcode Command Line Tools: インストール済み"
fi

# --------------------------------------------------------
# 2. Homebrew
# --------------------------------------------------------
if ! command -v brew &>/dev/null; then
    echo "[2/7] Homebrew をインストール中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "[2/7] Homebrew: インストール済み"
fi

# --------------------------------------------------------
# 3. git + fish（dotfiles clone に最低限必要）
# --------------------------------------------------------
echo "[3/7] git, fish をインストール中..."
brew install git fish

# --------------------------------------------------------
# 4. dotfiles clone & checkout
# --------------------------------------------------------
echo "[4/7] dotfiles をセットアップ中..."
mkdir -p "$BACKUP_DIR"

if [ -d "$DOTFILES_GIT" ]; then
    echo "  既存の .dotfiles.git を検出。バックアップして再クローンします。"
    mv "$DOTFILES_GIT" "$BACKUP_DIR/.dotfiles.git.bak"
fi

git clone --bare "$REMOTE_URL" "$DOTFILES_GIT"
dotfiles config status.showUntrackedFiles no
dotfiles config init.defaultBranch main

# checkout（コンフリクト時はバックアップして再試行）
if ! dotfiles checkout 2>/dev/null; then
    echo "  コンフリクトするファイルをバックアップします..."
    dotfiles checkout 2>&1 | grep "^\t" | while read -r file; do
        file=$(echo "$file" | xargs)
        if [ -f "$HOME/$file" ]; then
            mkdir -p "$(dirname "$BACKUP_DIR/$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
            echo "    バックアップ: $file"
        fi
    done
    dotfiles checkout
fi
echo "  checkout 完了"

# submodule
echo "  submodule を初期化中..."
dotfiles submodule update --init --recursive
echo "  submodule 初期化完了"

# --------------------------------------------------------
# 5. Brewfile でアプリ一括インストール
# --------------------------------------------------------
echo "[5/7] Brewfile からアプリをインストール中..."
if [ -f "$HOME/Brewfile" ]; then
    brew bundle --file="$HOME/Brewfile" || true
    echo "  Brewfile インストール完了（一部失敗はスキップ済み）"
else
    echo "  警告: ~/Brewfile が見つかりません。スキップします。"
fi

# --------------------------------------------------------
# 6. fish plugin (fisher)
# --------------------------------------------------------
echo "[6/7] fish plugin をインストール中..."
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
# 7. tmux plugin manager (TPM)
# --------------------------------------------------------
echo "[7/7] tmux plugin をセットアップ中..."
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
