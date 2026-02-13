if status is-interactive
    # Commands to run in interactive sessions can go here
end

# brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# uv
fish_add_path $HOME/.local/bin

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/Users/yuki.c.watanabe/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# gh
alias ges='GH_HOST=github.dena.jp gh'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/yuki.c.watanabe/google-cloud-sdk/path.fish.inc' ]; . '/Users/yuki.c.watanabe/google-cloud-sdk/path.fish.inc'; end

# jetbrains
fish_add_path "/Users/yuki.c.watanabe/Library/Application Support/JetBrains"

# alisases
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

alias cpv="~/go/bin/claude-plans-viewer"

# starship
starship init fish | source

