# zsh prompt: user@host:~$ 
PROMPT="%F{blue}%n%f@%F{magenta}%m%f:%F{green}%~%f$ "

# environment vars
export EDITOR=vim
export LS_COLORS="di=36:fi=0:ln=93:ex=32"
export PAGER="less"
export LESS="-FRX"
export TMUX_GTA=20000
export BROWSER=wslview

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

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias brd="bun run dev"
alias brdo="bun run dev -- --open"
alias brb="bun run build"

# tmux
alias tmls="tmux list-sessions"
alias tmdev="script -c tmux /dev/null"
alias tma="tmux attach"
alias tmka="tmux kill-server"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# uv Python package manager
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# echo PATH formatted (dependent aliases, must be at .zshrc bottom)
alias echopath="echo '$PATH' | tr ':' '\n'"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Claude Code docker container
devcon() { docker exec -it "claude-dev-${1:-1}" zsh; }
