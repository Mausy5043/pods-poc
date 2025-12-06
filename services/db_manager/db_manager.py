#!/usr/bin/env python3

import os
import shutil
import time
from datetime import datetime

DB_PATH = os.getenv("DB_PATH", "/data/pods-poc.db")
BACKUP_DIR = os.getenv("BACKUP_DIR", "/data/backups")
BACKUP_INTERVAL = int(os.getenv("BACKUP_INTERVAL", 8 * 3600))  # default: 3× per day


def ensure_backup_dir():
    os.makedirs(BACKUP_DIR, exist_ok=True)


def backup_db():
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(BACKUP_DIR, f"pods-poc_{ts}.db")
    if os.path.exists(DB_PATH):
        shutil.copy2(DB_PATH, dest)
        print(f"[backup] -> {dest}")
    else:
        print("[backup] No DB found")


def main():
    ensure_backup_dir()
    while True:
        backup_db()
        time.sleep(BACKUP_INTERVAL)


if __name__ == "__main__":
    main()
