#!/usr/bin/env bash
# install.sh: install dlink-dst as a system-wide systemd service and timer.
#
# Usage:
#   ./install.sh                 # prompts for the router admin password
#   DLINK_PASSWORD=... ./install.sh
#
# Requires root (or sudo). Copies dlink-dst to /usr/local/bin/, renders
# dlink-dst.service with your password into /etc/systemd/system/ (mode 600),
# copies dlink-dst.timer, and enables the timer. The password lives only in
# the rendered unit, never in this repository.

set -eu

SRC_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BIN=/usr/local/bin/dlink-dst
UNIT_DIR=/etc/systemd/system

# --- privilege ---
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        # -E keeps DLINK_PASSWORD in the environment.
        exec sudo -E "$0" "$@"
    fi
    echo "error: must run as root (sudo not found)" >&2
    exit 1
fi

# --- password ---
if [ -z "${DLINK_PASSWORD:-}" ]; then
    printf 'Router admin password: ' >&2
    read -r -s DLINK_PASSWORD
    echo >&2
fi
[ -n "$DLINK_PASSWORD" ] || { echo "error: no password given" >&2; exit 1; }

# --- script ---
install -m 755 "$SRC_DIR/dlink-dst" "$BIN"

# --- units ---
# Use | as the sed delimiter so passwords containing / don't break it.
sed "s|__DLINK_PASSWORD__|$DLINK_PASSWORD|" "$SRC_DIR/dlink-dst.service" \
    > "$UNIT_DIR/dlink-dst.service"
chmod 600 "$UNIT_DIR/dlink-dst.service"
install -m 644 "$SRC_DIR/dlink-dst.timer" "$UNIT_DIR/dlink-dst.timer"

# --- enable ---
systemctl daemon-reload
systemctl enable --now dlink-dst.timer

echo "Installed."
echo "  script: $BIN"
echo "  units:  $UNIT_DIR/dlink-dst.{service,timer}"
echo
echo "Check: systemctl status dlink-dst.timer"
