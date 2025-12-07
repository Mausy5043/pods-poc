#!/usr/bin/env python3

import os
import shutil
import subprocess
from datetime import datetime

DB_PATH = os.getenv("DB_PATH", "/data/pods-poc.db")
BACKUP_DIR = os.getenv("BACKUP_DIR", "/data/backups")
# default: 3× per day
BACKUP_INTERVAL = int(os.getenv("BACKUP_INTERVAL", 8 * 3600))

# Optional rclone remote (e.g. "dropbox:pods-poc_poc") to push backups
RCLONE_REMOTE = os.getenv("RCLONE_REMOTE", os.getenv("DROPBOX_REMOTE", ""))
# Behavior flags (can be set via env vars or config mapping at runtime)
ON_START_SYNC = os.getenv("ON_START_SYNC", "false").lower() in ("1", "true", "yes")
ON_SHUTDOWN_SYNC = os.getenv("ON_SHUTDOWN_SYNC", "false").lower() in (
    "1",
    "true",
    "yes",
)


def ensure_backup_dir():
    """Ensure the configured backup directory exists."""
    os.makedirs(BACKUP_DIR, exist_ok=True)


def backup_db():
    """Copy the DB file to the backup directory with a timestamped name."""
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(BACKUP_DIR, f"pods-poc_{ts}.db")
    if os.path.exists(DB_PATH):
        shutil.copy2(DB_PATH, dest)
        print(f"[backup] -> {dest}")
    else:
        print("[backup] No DB found")


def _rclone_sync():
    """If configured, attempt to sync backups to an rclone remote.

    This is intentionally best-effort: failures are logged but do not stop
    the backup loop.
    """
    if not RCLONE_REMOTE:
        return

    # rclone should be available in the runtime image (or on PATH)
    rclone_cmd = ["rclone", "copy", BACKUP_DIR, RCLONE_REMOTE]
    try:
        print(f"[backup] syncing backups -> {RCLONE_REMOTE}")
        subprocess.run(rclone_cmd, check=True)
        print("[backup] rclone sync completed")
    except FileNotFoundError:
        print("[backup] rclone not found in image; skipping remote sync")
    except subprocess.CalledProcessError as exc:
        print(f"[backup] rclone sync failed: {exc}")


def main():
    ensure_backup_dir()
    # Run a single backup and optionally push to remote (one-shot mode).
    # This file previously ran a continuous loop; we keep a one-shot
    # behavior so orchestration or host scheduling can control execution.

    # optional initial sync is expected to be handled by the pull script
    backup_db()

    # Optionally perform a one-off push when RCLONE_PUSH_ONCE env is true
    if os.getenv("RCLONE_PUSH_ONCE", "false").lower() in ("1", "true", "yes"):
        _rclone_sync()


if __name__ == "__main__":
    main()
