#!/bin/bash
# Install all apt packages required by dotfiles
set -euo pipefail

sudo apt update

# Standard packages
sudo apt install -y bat git vim tmux zsh less python3 postgresql-client curl build-essential xterm gpg wget

# eza - requires external repo
if ! command -v eza &>/dev/null; then
  echo "Installing eza from deb.gierens.de..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
else
  echo "eza is already installed."
fi

echo "All packages installed."
