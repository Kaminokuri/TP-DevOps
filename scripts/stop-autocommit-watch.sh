#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="autocommit-watch.service"
SYSTEM_UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required to stop the autocommit watcher service." >&2
  exit 1
fi

systemctl disable --now "${SERVICE_NAME}" >/dev/null 2>&1 || true
rm -f "${SYSTEM_UNIT_FILE}"
systemctl daemon-reload
echo "Autocommit watcher stopped."
