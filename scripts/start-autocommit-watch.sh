#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_FILE="${ROOT_DIR}/scripts/autocommit-watch.service"
SERVICE_NAME="autocommit-watch.service"
SYSTEM_UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required to start the autocommit watcher service." >&2
  exit 1
fi

install -m 0644 "${UNIT_FILE}" "${SYSTEM_UNIT_FILE}"
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"
systemctl --no-pager --full status "${SERVICE_NAME}" | sed -n '1,12p'
