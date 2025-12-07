#!/usr/bin/env bash

# install-units.sh
# Install example systemd units and helper scripts from this repository into the system.
# Run as the repo owner and with sudo when copying to system locations.

set -euo pipefail

usage() {
  cat <<EOF
Usage: sudo ./install-units.sh [--enable-all]

This script copies example systemd unit files from ./systemd into /etc/systemd/system,
installs helper scripts to /usr/local/bin, replaces the placeholder /path/to/repo in unit files
with the current repository path, reloads systemd, and optionally enables the monitor timer and
the example container units.

Options:
  --enable-all    Enable and start monitor timer and example container services (web, collector, trend, storage)
EOF
}

ENABLE_ALL=0
if [ "${1-}" = "--enable-all" ]; then
  ENABLE_ALL=1
fi

REPO_DIR=$(pwd)
SYSTEMD_DIR=/etc/systemd/system

echo "Installing systemd units from $(pwd)/systemd to $SYSTEMD_DIR"

for f in systemd/*.service systemd/*.timer; do
  [ -f "$f" ] || continue
  dst="$SYSTEMD_DIR/$(basename "$f")"
  echo "Templating $f -> $dst"
  sed "s|/path/to/repo|$REPO_DIR|g" "$f" | sudo tee "$dst" >/dev/null
done

echo "Installing scripts to /usr/local/bin"
sudo mkdir -p /usr/local/bin
for s in systemd/*.sh; do
  [ -f "$s" ] || continue
  base=$(basename "$s")
  dst="/usr/local/bin/$base"
  echo "Copying $s -> $dst"
  sudo cp "$s" "$dst"
  sudo chmod +x "$dst"
done

echo "Creating marker directories under /var/lib/pods-poc"
sudo mkdir -p /var/lib/pods-poc/reported /var/lib/pods-poc/reports
sudo chown root:root /var/lib/pods-poc -R

echo "Reloading systemd daemon"
sudo systemctl daemon-reload

if [ "$ENABLE_ALL" -eq 1 ]; then
  echo "Enabling monitor timer and example services"
  sudo systemctl enable --now pods-poc-monitor.timer
  sudo systemctl enable --now pods-poc-web.service pods-poc-collector.service pods-poc-trend.service pods-poc-storage.service || true
fi

echo "Install complete. Review units in $SYSTEMD_DIR and adjust as necessary before enabling."
echo "To enable monitor only: sudo systemctl enable --now pods-poc-monitor.timer"
