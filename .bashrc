### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/yuki.c.watanabe/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# uv
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/.local/bin/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# gh
alias ges='GH_HOST=github.dena.jp gh'

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then
    . "$HOME/google-cloud-sdk/path.bash.inc"
fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then
    . "$HOME/google-cloud-sdk/completion.bash.inc"
fi

# jetbrains
export PATH="$HOME/Library/Application Support/JetBrains:$PATH"

# aliases
alias g="git"
alias gs="git switch"
alias gc="git commit"
alias ga="git add"
alias gp="git pull"
alias gsd="git switch develop"

alias gclean="git branch --merged | grep -v '*' | grep -vE '^\s*(main|master)\$' | xargs git branch -d"

alias pc="pycharm"
alias ws="webstorm"

alias cc="claude"
alias ccd="claude --dangerously-skip-permissions"

# dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'

# mise
eval "$(mise activate bash)"

# starship
eval "$(starship init bash)"

alias claude-mem='bun "/Users/yuki.c.watanabe/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
