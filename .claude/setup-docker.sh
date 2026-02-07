#!/bin/bash
# Setup persistent Claude Code Docker container for WSL
# Run this on a fresh WSL install after Docker is available.

set -euo pipefail

IMAGE_NAME="claude-code-env"
CONTAINER_NAME="claude-dev"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build image if it doesn't exist
if ! docker image inspect "${IMAGE_NAME}:latest" &>/dev/null; then
  echo "Building ${IMAGE_NAME} image..."
  docker build -t "${IMAGE_NAME}:latest" "${DOCKERFILE_DIR}"
else
  echo "Image ${IMAGE_NAME}:latest already exists, skipping build."
fi

# Create container if it doesn't exist
if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  echo "Container ${CONTAINER_NAME} already exists."
else
  echo "Creating ${CONTAINER_NAME} container..."
  docker create -it \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --network host \
    --tmpfs /tmp:exec,size=2g \
    -v "${HOME}:${HOME}" \
    -w "${HOME}" \
    "${IMAGE_NAME}:latest"
fi

# Start container if not running
if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  echo "Starting ${CONTAINER_NAME}..."
  docker start "${CONTAINER_NAME}"
else
  echo "${CONTAINER_NAME} is already running."
fi

echo "Done. Use: docker exec -it ${CONTAINER_NAME} zsh"
