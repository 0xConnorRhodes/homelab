#!/usr/bin/env bash

set -e

# --- Configuration ---
CONTAINER_NAME="readeck"
CONTAINER_BACKUP_PATH="/readeck/export.zip"
HOST_BACKUP_FILENAME="$(date +%y%m%d)-readeck.zip"
# ---------------------

echo "Creating backup file inside container: ${CONTAINER_BACKUP_PATH}"
docker exec "${CONTAINER_NAME}" readeck export -config /readeck/config.toml "${CONTAINER_BACKUP_PATH}"

echo "Copying backup to host: ./${HOST_BACKUP_FILENAME}"
docker cp "${CONTAINER_NAME}:${CONTAINER_BACKUP_PATH}" "./${HOST_BACKUP_FILENAME}"

echo "Cleaning up backup file inside container..."
docker exec "${CONTAINER_NAME}" rm "${CONTAINER_BACKUP_PATH}"

echo "Backup successful: ./${HOST_BACKUP_FILENAME}"
