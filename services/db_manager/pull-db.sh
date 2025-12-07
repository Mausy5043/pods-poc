#!/usr/bin/env sh
set -eu

# Pull latest backups from the configured rclone remote into the local backup dir
RCLONE_REMOTE="${RCLONE_REMOTE:-${DROPBOX_REMOTE:-}}"
DB_PATH="${DB_PATH:-/data/pods-poc.db}"
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"

if [ -z "$RCLONE_REMOTE" ]; then
  echo "RCLONE_REMOTE not set; aborting"
  exit 1
fi

echo "[storage] pulling backups from ${RCLONE_REMOTE} -> ${BACKUP_DIR}"
mkdir -p "$BACKUP_DIR"
if ! rclone copy "$RCLONE_REMOTE" "$BACKUP_DIR"; then
  echo "[storage] rclone copy failed"
  exit 2
fi

# restore most recent backup (if any) to DB_PATH
latest=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -n1 || true)
if [ -n "$latest" ]; then
  echo "[storage] restoring $latest -> $DB_PATH"
  cp "$BACKUP_DIR/$latest" "$DB_PATH"
else
  echo "[storage] no backups found at $BACKUP_DIR"
fi

echo "[storage] pull complete"
