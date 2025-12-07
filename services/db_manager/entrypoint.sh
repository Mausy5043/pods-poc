#!/usr/bin/env sh
set -eu

cmd="${1:-}"
case "$cmd" in
  pull)
    exec /usr/local/bin/pull-db.sh
    ;;
  push)
    exec /usr/local/bin/push-db.sh
    ;;
  backup)
    exec /usr/local/bin/backup-once.sh
    ;;
  help|--help|-h|"")
    echo "Usage: $0 {pull|push|backup}"
    echo "Environment variables: RCLONE_REMOTE (or DROPBOX_REMOTE), DB_PATH, BACKUP_DIR"
    exit 0
    ;;
  *)
    # allow arbitrary commands to run in the container
    exec "$@"
    ;;
esac
