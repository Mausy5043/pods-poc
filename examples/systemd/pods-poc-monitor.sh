#!/usr/bin/env bash
# pods-poc-monitor.sh
# Periodically scans for crashed pods/containers and sends email via pymail.py

set -euo pipefail

REPORT_DIR=/var/lib/pods-poc/reported
TMPDIR=/tmp/pods-poc-logs
MAILCMD=/usr/local/bin/pymail.py
mkdir -p "$REPORT_DIR" "$TMPDIR"

ADMIN_SUBJECT_PREFIX="pods-poc container failure"

while IFS= read -r line; do
  name=$(echo "$line" | cut -d'|' -f1)
  status=$(echo "$line" | cut -d'|' -f2)
  exitcode=$(echo "$line" | cut -d'|' -f3)

  if [ "$status" != "exited" ]; then
    continue
  fi
  if [ "$exitcode" -eq 0 ]; then
    continue
  fi

  marker="$REPORT_DIR/$name.reported"
  if [ -f "$marker" ]; then
    continue
  fi

  reportfile="$TMPDIR/${name}-$(date +%Y%m%d%H%M%S).log"
  echo "Collecting logs for $name" > "$reportfile"
  podman ps -a --filter "name=$name" --no-trunc >> "$reportfile" 2>&1 || true
  echo "--- container logs ---" >> "$reportfile"
  podman logs --tail 500 "$name" >> "$reportfile" 2>&1 || true
  echo "--- journal ---" >> "$reportfile"
  journalctl -u "$name" --since "1 hour ago" >> "$reportfile" 2>&1 || true

  if [ -x "$MAILCMD" ]; then
    "$MAILCMD" -s "$ADMIN_SUBJECT_PREFIX: $name exited (code $exitcode)" -f "$reportfile" || true
  fi

  touch "$marker"
done < <(podman ps -a --format "{{.Names}}|{{.Status}}|{{.ExitCode}}" --filter status=exited)
