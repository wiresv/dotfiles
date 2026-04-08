#!/bin/bash
# Install everything the dotfiles depend on, on macOS.
# Idempotent — safe to re-run. Counterpart to apt-setup.sh.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "mac-setup.sh: this script is for macOS only (detected: $(uname -s))" >&2
  exit 1
fi

# --- Homebrew --------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to the current shell's PATH so the rest of this script can use it.
  if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed."
fi

# --- Homebrew formulae -----------------------------------------------------
# Tools assumed by the dotfiles / scripts under ~/.local/bin.
# jq is used by wifi-speed; node provides npm for global CLI installs below.
brew_pkgs=(jq node)
for pkg in "${brew_pkgs[@]}"; do
  if brew list --formula "$pkg" &>/dev/null; then
    echo "$pkg already installed."
  else
    echo "Installing $pkg..."
    brew install "$pkg"
  fi
done

# --- Global npm CLIs -------------------------------------------------------
# fast-cli: Netflix Open Connect speed test, used by ~/.local/bin/wifi-speed.
if ! command -v fast &>/dev/null; then
  echo "Installing fast-cli (Netflix Open Connect speed test)..."
  npm install -g fast-cli
else
  echo "fast-cli already installed."
fi

# --- Notes about built-ins -------------------------------------------------
# The following are macOS built-ins and need no install:
#   networkquality   — Apple's RPM/bufferbloat test (/usr/bin/networkquality)
#   curl             — used by wifi-speed for Cloudflare endpoints
#   system_profiler  — used by wifi-speed for WiFi context (SSID, RSSI, etc.)

echo
echo "mac-setup complete. Try: wifi-speed"
