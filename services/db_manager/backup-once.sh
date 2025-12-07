#!/usr/bin/env sh
set -eu

DB_PATH="${DB_PATH:-/data/pods-poc.db}"
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"

mkdir -p "$BACKUP_DIR"
ts=$(date +%Y%m%d_%H%M%S)
dest="$BACKUP_DIR/pods-poc_${ts}.db"
if [ -f "$DB_PATH" ]; then
  cp "$DB_PATH" "$dest"
  echo "[backup] -> $dest"
else
  echo "[backup] no DB at $DB_PATH"
  exit 1
fi
