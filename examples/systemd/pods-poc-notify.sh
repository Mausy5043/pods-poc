#!/usr/bin/env bash
# pods-poc-notify.sh
# Gather logs for a failed unit/container and send email using pymail.py

set -euo pipefail

REPO_DIR=/path/to/repo
NAME="$1"
REPORT_DIR=/var/lib/pods-poc/reports
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/${NAME}-$(date +%Y%m%d%H%M%S).log"

echo "pods-poc notifier report for: $NAME" > "$REPORT_FILE"
echo "Host: $(hostname)" >> "$REPORT_FILE"
echo "Date: $(date --iso-8601=seconds)" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

echo "Podman ps -a:" >> "$REPORT_FILE"
podman ps -a --no-trunc >> "$REPORT_FILE" 2>&1 || true
echo >> "$REPORT_FILE"

echo "Container logs (last 500 lines) for $NAME:" >> "$REPORT_FILE"
podman logs --tail 500 "$NAME" >> "$REPORT_FILE" 2>&1 || true
echo >> "$REPORT_FILE"

echo "Journal (last 1h) for unit $NAME:" >> "$REPORT_FILE"
journalctl -u "$NAME" --since "1 hour ago" >> "$REPORT_FILE" 2>&1 || true

# Send email using pymail.py if available
MAILCMD=/usr/local/bin/pymail.py
if [ ! -x "$MAILCMD" ]; then
  MAILCMD=$(which pymail.py 2>/dev/null || true)
fi
if [ -n "$MAILCMD" ] && [ -x "$MAILCMD" ]; then
  "$MAILCMD" -s "pods-poc failure: $NAME on $(hostname)" -f "$REPORT_FILE" || true
else
  echo "pymail.py not found; report saved to $REPORT_FILE"
fi
