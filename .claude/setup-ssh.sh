#!/bin/bash
# Setup SSH server in a devcon container. Usage: setup-ssh.sh <port>
set -e

PORT="${1:?Usage: setup-ssh.sh <port>}"

# Install openssh-server if not present
if ! command -v sshd &>/dev/null; then
  apt-get update && apt-get install -y openssh-server && rm -rf /var/lib/apt/lists/*
fi

# Configure sshd
mkdir -p /run/sshd
cat > /etc/ssh/sshd_config.d/devcon.conf <<EOF
Port $PORT
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
EOF

# Generate host keys if missing
ssh-keygen -A

# Generate ed25519 key pair if missing
if [ ! -f /root/.ssh/id_ed25519 ]; then
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -q
fi

# Ensure public key is in authorized_keys
mkdir -p /root/.ssh && chmod 700 /root/.ssh
grep -qxF "$(cat /root/.ssh/id_ed25519.pub)" /root/.ssh/authorized_keys 2>/dev/null \
  || cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Start or restart sshd
pkill -f "sshd.*$PORT" 2>/dev/null || true
/usr/sbin/sshd -E /var/log/sshd.log
echo "SSH server running on port $PORT"
