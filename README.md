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

### 3. Set up Claude Code Docker containers (optional)

```
bash ~/.claude/setup-docker.sh
```

This builds the `claude-code-env` Docker image. Once built, use `devcon {N}` to create and enter containers:

```
devcon 1   # creates claude-dev-1 if it doesn't exist, then enters it
devcon 2   # creates claude-dev-2 if it doesn't exist, then enters it
```

Each container gets a hostname matching its index (e.g. `devcon1`, `devcon2`) so the shell prompt shows which container you're in.
