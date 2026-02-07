# zsh prompt: user@host:~$
PROMPT="%F{blue}%n%f@%F{magenta}%m%f:%F{green}%~%f$ "

# environment vars
export EDITOR=vim
export LS_COLORS="di=36:fi=0:ln=93:ex=32"
export PAGER="less"
export LESS="-FRX"
export TMUX_GTA=20000
export BROWSER=wslview
export BAT_THEME="ansi"

# Fix terminal dimensions for tmux/WSL/Windows Terminal
if [[ -n "$TMUX" ]]; then
    eval $(resize)
fi
trap 'eval $(resize)' WINCH

# python
export PATH="`python3 -m site --user-base`/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# uv Python package manager
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# aliases (sourced last so PATH is fully set for echopath)
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"
