# dotfiles

bare repository 方式で管理する dotfiles。

## 新マシンセットアップ

### ワンライナー

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ukwhatn/dotfiles/refs/heads/main/dotfiles/scripts/bootstrap.sh)
```

または SSH clone:

```bash
curl -fsSL https://raw.githubusercontent.com/ukwhatn/dotfiles/refs/heads/main/dotfiles/scripts/bootstrap.sh -o /tmp/bootstrap.sh
bash /tmp/bootstrap.sh git@github.com:ukwhatn/dotfiles.git
```

### bootstrap.sh がやること

| ステップ | 内容 |
|---------|------|
| 1 | Xcode Command Line Tools |
| 2 | Homebrew インストール |
| 3 | git, fish インストール |
| 4 | dotfiles clone & checkout（コンフリクト時は自動バックアップ） |
| 5 | `~/Brewfile` で brew/cask/mas アプリ一括インストール |
| 6 | fisher + fish plugins インストール |
| 7 | 開発環境セットアップ（mise install, uv, bun） |
| 8 | tmux plugin manager (TPM) インストール |

### セットアップ後の手動作業

1. **デフォルトシェルを fish に変更**
   ```bash
   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/fish
   ```

2. **tmux プラグインインストール**: tmux 起動後に `prefix + I`

3. **Mac App Store アプリ**: Apple ID でログイン済みなら Brewfile の `mas` 行で自動インストールされる。未ログインなら手動で `mas install <id>`

4. **各アプリの初期設定**: 1Password, Google Chrome, etc.

## 日常の管理

```fish
# 状態確認
dotfiles status

# 変更を追加・コミット
dotfiles add <file>
dotfiles commit -m "メッセージ"
dotfiles push
```

## 構成

```
~
├── .dotfiles.git/          # bare repository
├── .gitignore              # ホワイトリスト方式
├── Brewfile                # Homebrew/cask/mas 一括管理
├── .tmux.conf
├── .config/
│   ├── fish/               # fish shell 設定
│   ├── starship.toml       # starship プロンプト
│   ├── karabiner/          # Karabiner-Elements
│   ├── mise/               # mise (asdf互換)
│   └── gh/                 # GitHub CLI
├── .claude/                # Claude Code 設定 (submodule)
├── .ssh/                   # SSH 設定 (submodule)
├── .secrets/               # 秘匿情報 (submodule)
└── dotfiles/
    ├── scripts/
    │   ├── bootstrap.sh    # 新マシン用セットアップ (bash)
    │   └── setup.fish      # dotfiles のみセットアップ (fish)
    └── README.md
```
