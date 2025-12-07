#!/usr/bin/env sh
set -eu

RCLONE_REMOTE="${RCLONE_REMOTE:-${DROPBOX_REMOTE:-}}"
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"

if [ -z "$RCLONE_REMOTE" ]; then
  echo "RCLONE_REMOTE not set; aborting"
  exit 1
fi

echo "[storage] pushing backups from $BACKUP_DIR -> $RCLONE_REMOTE"
if ! rclone copy "$BACKUP_DIR" "$RCLONE_REMOTE"; then
  echo "[storage] rclone push failed"
  exit 2
fi

echo "[storage] push completed"
