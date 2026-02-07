FROM node:20-bookworm-slim

# 1. Install system essentials + zsh only
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    build-essential \
    curl \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# 3. Set working directory
WORKDIR /app

# 4. Set the ENV variable so scripts/terminals know zsh is the default
ENV SHELL=/bin/zsh

# 5. Default entrypoint drops you into zsh
CMD ["zsh"]