#!/opt/homebrew/bin/fish

# 新マシン用dotfilesセットアップスクリプト
# 使い方: fish dotfiles/scripts/setup.fish <remote_url>

set -l DOTFILES_GIT "$HOME/.dotfiles.git"
set -l BACKUP_DIR "$HOME/.dotfiles-backup-"(date "+%Y%m%d%H%M%S")

if test (count $argv) -lt 1
    echo "使い方: fish setup.fish <remote_url>"
    echo "例: fish setup.fish git@github.com:ukwhatn/dotfiles.git"
    exit 1
end

set -l REMOTE_URL $argv[1]

function dotfiles
    git --git-dir=$DOTFILES_GIT --work-tree=$HOME $argv
end

echo "=== dotfilesセットアップ開始 ==="

# 1. 既存dotfilesをバックアップ
echo "既存ファイルのバックアップ: $BACKUP_DIR"
mkdir -p $BACKUP_DIR

# checkoutでコンフリクトするファイルを事前にバックアップ
set -l conflicting_files
if test -d $DOTFILES_GIT
    echo "既存の .dotfiles.git が見つかりました。削除して再クローンします。"
    rm -rf $DOTFILES_GIT
end

# 2. bare repoをクローン
echo "bare repoをクローン: $REMOTE_URL"
if not git clone --bare $REMOTE_URL $DOTFILES_GIT
    echo "エラー: git clone --bare 失敗"
    exit 1
end

# 未追跡ファイルを非表示
dotfiles config status.showUntrackedFiles no

# 3. checkout（コンフリクト時はバックアップして再試行）
echo "checkoutを実行..."
set -l checkout_output (dotfiles checkout 2>&1)
set -l checkout_status $status

if test $checkout_status -ne 0
    echo "コンフリクトするファイルをバックアップします..."

    # コンフリクトファイルを抽出してバックアップ
    for line in $checkout_output
        # "	.bashrc" のようなインデント付きファイル名を抽出
        set -l file (string trim -- $line)
        if test -f "$HOME/$file"
            set -l dir (dirname "$BACKUP_DIR/$file")
            mkdir -p $dir
            mv "$HOME/$file" "$BACKUP_DIR/$file"
            echo "  バックアップ: $file"
        end
    end

    # 再試行
    if not dotfiles checkout
        echo "エラー: checkout失敗。手動で確認してください。"
        echo "バックアップ先: $BACKUP_DIR"
        exit 1
    end
end

echo "checkout完了"

# 4. デフォルトブランチ設定
dotfiles config init.defaultBranch main

# 5. submodule初期化
echo "submoduleを初期化..."
if not dotfiles submodule update --init --recursive
    echo "エラー: submodule初期化失敗"
    exit 1
end
echo "submodule初期化完了"

# 6. LaunchAgent登録
set -l PLIST "$HOME/Library/LaunchAgents/com.user.dotfiles-sync.plist"
if test -f $PLIST
    echo "LaunchAgentを登録..."
    launchctl load $PLIST
    echo "LaunchAgent登録完了"
else
    echo "警告: LaunchAgent plistが見つかりません: $PLIST"
end

echo ""
echo "=== セットアップ完了 ==="
echo "バックアップ先: $BACKUP_DIR"
echo ""
echo "確認コマンド:"
echo "  dotfiles status"
echo "  dotfiles submodule status"
echo "  launchctl list | grep dotfiles-sync"
