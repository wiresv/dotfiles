FROM node:20-bookworm-slim

# 1. Install system essentials + zsh only
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    build-essential \
    curl \
    zsh \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# 3. Copy SSH setup script
COPY setup-ssh.sh /root/.claude/setup-ssh.sh
RUN chmod +x /root/.claude/setup-ssh.sh

# 4. Set working directory
WORKDIR /root

# 5. Set the ENV variable so scripts/terminals know zsh is the default
ENV SHELL=/bin/zsh

# 6. Default entrypoint drops you into zsh
CMD ["zsh"]