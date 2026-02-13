#!/opt/homebrew/bin/fish

# dotfilesリポジトリとsubmoduleの自動同期スクリプト
# LaunchAgent (WatchPaths + StartCalendarInterval) から起動される

set -l LOG_FILE "$HOME/Library/Logs/dotfiles-sync.log"
set -l GIT_DIR "$HOME/.dotfiles.git"
set -l WORK_TREE "$HOME"
# .claudeは自動同期対象外
set -l SYNC_SUBMODULES .secrets .config/fish/functions .ssh

function log_msg
    echo (date "+%Y-%m-%d %H:%M:%S") "[$argv[1]]" $argv[2..] >> $LOG_FILE
end

function dotfiles
    git --git-dir=$GIT_DIR --work-tree=$WORK_TREE $argv
end

# ネットワーク接続チェック
if not nc -z -w 5 github.com 22 2>/dev/null
    log_msg "SKIP" "ネットワーク未接続のためスキップ"
    exit 0
end

log_msg "INFO" "同期開始"

# --- dotfilesリポジトリの同期 ---

# リモートが設定されているか確認
set -l has_remote (dotfiles remote 2>/dev/null | head -1)

if test -n "$has_remote"
    # pull --rebase
    if not dotfiles pull --rebase 2>>$LOG_FILE
        log_msg "ERROR" "dotfiles pull --rebase 失敗。rebase中断の可能性あり"
        dotfiles rebase --abort 2>/dev/null
        exit 1
    end
end

# 変更検知 + commit
set -l changes (dotfiles status --porcelain 2>/dev/null)
if test -n "$changes"
    dotfiles add -u 2>>$LOG_FILE
    dotfiles commit -m "auto: dotfilesを自動同期 ($(hostname -s))" 2>>$LOG_FILE
    log_msg "INFO" "dotfiles変更をcommit"

    if test -n "$has_remote"
        if not dotfiles push 2>>$LOG_FILE
            log_msg "ERROR" "dotfiles push 失敗"
            exit 1
        end
        log_msg "INFO" "dotfiles push完了"
    end
else
    log_msg "INFO" "dotfilesに変更なし"
end

# --- submodule同期 ---

set -l submodule_updated false

for sm in $SYNC_SUBMODULES
    set -l sm_path "$WORK_TREE/$sm"

    if not test -d "$sm_path/.git"; and not test -f "$sm_path/.git"
        log_msg "WARN" "submodule $sm が初期化されていません"
        continue
    end

    log_msg "INFO" "submodule $sm の同期開始"

    # submoduleリポジトリ内でpull
    if not git -C "$sm_path" pull --rebase 2>>$LOG_FILE
        log_msg "ERROR" "submodule $sm の pull --rebase 失敗"
        git -C "$sm_path" rebase --abort 2>/dev/null
        continue
    end

    # submoduleリポジトリ内の変更を検知・commit・push
    set -l sm_changes (git -C "$sm_path" status --porcelain 2>/dev/null)
    if test -n "$sm_changes"
        git -C "$sm_path" add -A 2>>$LOG_FILE
        git -C "$sm_path" commit -m "auto: 自動同期 ($(hostname -s))" 2>>$LOG_FILE
        log_msg "INFO" "submodule $sm 変更をcommit"

        if not git -C "$sm_path" push 2>>$LOG_FILE
            log_msg "ERROR" "submodule $sm push 失敗"
            continue
        end
        log_msg "INFO" "submodule $sm push完了"
    end

    # dotfiles側でsubmodule refが変わったか確認
    set -l ref_changed (dotfiles diff --name-only -- "$sm" 2>/dev/null)
    if test -n "$ref_changed"
        set submodule_updated true
    end
end

# submodule refの更新をdotfilesリポジトリにcommit
if test "$submodule_updated" = true
    dotfiles add .secrets .config/fish/functions .ssh 2>>$LOG_FILE
    dotfiles commit -m "auto: submodule refを更新 ($(hostname -s))" 2>>$LOG_FILE
    log_msg "INFO" "submodule ref更新をcommit"

    if test -n "$has_remote"
        if not dotfiles push 2>>$LOG_FILE
            log_msg "ERROR" "submodule ref更新のpush失敗"
            exit 1
        end
        log_msg "INFO" "submodule ref更新 push完了"
    end
end

log_msg "INFO" "同期完了"
