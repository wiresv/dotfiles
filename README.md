# dotfiles

Personal dotfiles for quick setup on a fresh environment.

## Quick Start

### 1. Clone into home directory

```
cd ~
git init
git remote add origin https://github.com/wiresv/dotfiles.git
git fetch origin
git checkout -B main origin/main
source ~/.zshrc
```

### 2. Install all required apt packages

```
aptsetup
```

This runs `~/.config/scripts/apt-setup.sh` which installs everything the dotfiles depend on, including packages that need external repos (like eza).

### 3. Set up the Claude Code Docker container (optional)

```
bash ~/.claude/setup-docker.sh
```

Each run creates a new numbered container (`claude-dev-1`, `claude-dev-2`, ...) without touching existing ones. Enter a container with `devcon` or `devcon 2`.
