# zsh prompt: user@host:~$ 
PROMPT="%F{blue}%n%f@%F{magenta}%m%f:%F{green}%~%f$ "

# environment vars
export EDITOR=vim
export LS_COLORS="di=36:fi=0:ln=93:ex=32"
export PAGER="less"
export LESS="-FRX"
export TMUX_GTA=20000

# Fix terminal dimensions for tmux/WSL/Windows Terminal
if [[ -n "$TMUX" ]]; then
    # Get terminal size and export it
    eval $(resize)
fi

# Set up trap to update dimensions on window resize
trap 'eval $(resize)' WINCH

# shell
alias c="clear"
alias cd..="cd .."
alias zconf="code ~/.zshrc"
alias ls="eza -bhlF --no-user --no-permissions --no-time --group-directories-first"
alias sl="eza -bhlF --no-user --no-permissions --no-time --group-directories-first"
alias lsa="eza -abhlF --no-user --no-permissions --no-time --group-directories-first"
export BAT_THEME="ansi"
alias cat="bat"
alias bat="batcat"
alias atop="sudo asitop --color 7"

# git
alias gits="git status"
alias gita="git add ."
alias gitd="git diff"
alias gitc="git commit"
alias gitp="git push"
alias gitpu="git pull"
alias glg="git log --graph --pretty=format:'%C(blue)%h %ad%C(auto)%d %C(white)%s' --abbrev=4 --all --date=format:'%y-%m-%d %H:%M'"

# rust
alias car="cargo run"
alias care="cargo run --example"
alias cac="cargo clean"
alias cc="cargo check"
alias cab="cargo build"
alias cabr="cargo build --release"
alias carr="cargo run --release"
alias cabrr="cargo build --release && cargo run --release"
alias caf="cargo fmt"
# . "$HOME/.cargo/env"

# python
alias py="python3"
alias python="python3"
alias pip="pip3"
export PATH="`python3 -m site --user-base`/bin:$PATH"

# homebrew
alias brewbundle="brew bundle -f dump"
alias brewup="brew update && brew upgrade"

# apt
alias aptup="sudo apt update && sudo apt upgrade"

# AWS
alias cdks="cdk synth"
alias cdkd="cdk deploy"
alias cdkls="cdk ls"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias brd="bun run dev"
alias brdo="bun run dev -- --open"
alias brb="bun run build"
alias tmls="tmux list-sessions"
alias tmdev="script -c tmux /dev/null"
alias tma="tmux attach"
alias tmka="tmux kill-server"
alias gtu="tmux setenv -g TMUX_GTA"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# postgres
alias postgresmonitor="tail -f /var/log/postgresql/postgresql-*-main.log"

# claude
alias ccuse="bunx ccusage@latest" # --since 20250625

# zshrc remote machine copying
copy_zshrc() {
  scp ~/.zshrc "$1":~/.zshrc
  scp ~/.zshrc "$1":/var/lib/postgresql/.zshrc
}

# ssh, copying .rc files for persistent use
function sshenv() {
    if [ -z "$1" ]; then
        echo "Usage: sshenv user@host"
        return 1
    fi
    local REMOTE="$1"
    local REMOTE_DIR=".austin_rc"

    # Paths to local configuration files/directories
    local LOCAL_ZSHRC="$HOME/.zshrc"
    local LOCAL_VIMRC="$HOME/.vimrc"
    local LOCAL_PSQLRC="$HOME/.psqlrc"
    local LOCAL_CONFIG_DIR="$HOME/.config/"

    # Remote host paths (relative to home directory)
    local REMOTE_ZSHRC="$REMOTE_DIR/.zshrc"
    local REMOTE_VIMRC="$REMOTE_DIR/.vimrc"
    local REMOTE_PSQLRC="$REMOTE_DIR/.psqlrc"
    local REMOTE_CONFIG_DIR="$REMOTE_DIR/.config/"

    # Ensure the remote directory exists
    ssh "$REMOTE" "mkdir -p ~/$REMOTE_DIR"

    # Function to transfer file if it doesn't exist on the remote host
    transfer_if_not_exists() {
        local local_file="$1"
        local remote_file="$2"
        ssh "$REMOTE" "[ -e ~/$remote_file ]" || rsync -av --ignore-existing "$local_file" "$REMOTE:~/$remote_file"
    }

    # Transfer files only if they don't exist on the remote host
    transfer_if_not_exists "$LOCAL_ZSHRC" "$REMOTE_ZSHRC"
    transfer_if_not_exists "$LOCAL_VIMRC" "$REMOTE_VIMRC"
    transfer_if_not_exists "$LOCAL_PSQLRC" "$REMOTE_PSQLRC"

    # Check if the remote .config directory exists
    ssh "$REMOTE" "[ -d ~/$REMOTE_CONFIG_DIR ]" || rsync -av --ignore-existing --exclude 'unnecessary_dir/' "$LOCAL_CONFIG_DIR" "$REMOTE:~/$REMOTE_CONFIG_DIR"

    # SSH into the remote host with environment variables set
    ssh -t "$REMOTE" "
        export VIMINIT='source ~/$REMOTE_DIR/.vimrc';
        export PSQLRC=~/$REMOTE_DIR/.psqlrc;
        export XDG_CONFIG_HOME=~/$REMOTE_DIR/.config;
        export ZDOTDIR=~/$REMOTE_DIR;
        exec zsh -i;
    "
}

# uv Python package manager
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# echo PATH formatted (dependent aliases, must be at .zshrc bottom)
alias echopath="echo '$PATH' | tr ':' '\n'"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
