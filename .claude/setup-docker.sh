#!/bin/bash
# Setup persistent Claude Code Docker container for WSL
# Each run creates a new uniquely numbered container, never overwriting existing ones.

set -euo pipefail

IMAGE_NAME="claude-code-env"
CONTAINER_PREFIX="claude-dev"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build image if it doesn't exist
if ! docker image inspect "${IMAGE_NAME}:latest" &>/dev/null; then
  echo "Building ${IMAGE_NAME} image..."
  docker build -t "${IMAGE_NAME}:latest" "${DOCKERFILE_DIR}"
else
  echo "Image ${IMAGE_NAME}:latest already exists, skipping build."
fi

# Find the next available ID
LAST_ID=$(docker ps -a --format '{{.Names}}' \
  | grep -oP "^${CONTAINER_PREFIX}-\K[0-9]+" \
  | sort -n | tail -1 || true)
NEXT_ID=$(( ${LAST_ID:-0} + 1 ))
CONTAINER_NAME="${CONTAINER_PREFIX}-${NEXT_ID}"

# Create and start the new container
echo "Creating ${CONTAINER_NAME}..."
docker create -it \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --network host \
  --tmpfs /tmp:exec,size=2g \
  -w /app \
  "${IMAGE_NAME}:latest"

echo "Starting ${CONTAINER_NAME}..."
docker start "${CONTAINER_NAME}"

echo "Done. Use: docker exec -it ${CONTAINER_NAME} zsh"
