#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${ROOT_DIR}/.git/autocommit-watch.pid"
LOG_FILE="${ROOT_DIR}/.git/autocommit-watch.log"
LOCK_DIR="${ROOT_DIR}/.git/autocommit-watch.lock"
POLL_SECONDS="${AUTOCOMMIT_POLL_SECONDS:-2}"
QUIET_SECONDS="${AUTOCOMMIT_QUIET_SECONDS:-4}"
BRANCH="${AUTOCOMMIT_BRANCH:-$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)}"

status_snapshot() {
  git -C "${ROOT_DIR}" status --porcelain=v1 --untracked-files=all
}

acquire_lock() {
  mkdir "${LOCK_DIR}" 2>/dev/null
}

release_lock() {
  rmdir "${LOCK_DIR}" 2>/dev/null || true
}

cleanup() {
  rm -f "${PID_FILE}"
  release_lock
}

trap cleanup EXIT INT TERM

echo "$$" > "${PID_FILE}"
touch "${LOG_FILE}"

last_snapshot="$(status_snapshot)"
last_change_epoch="$(date +%s)"

while true; do
  sleep "${POLL_SECONDS}"

  current_snapshot="$(status_snapshot)"
  current_epoch="$(date +%s)"

  if [[ "${current_snapshot}" != "${last_snapshot}" ]]; then
    last_snapshot="${current_snapshot}"
    last_change_epoch="${current_epoch}"
    continue
  fi

  if [[ -z "${current_snapshot}" ]]; then
    continue
  fi

  if (( current_epoch - last_change_epoch < QUIET_SECONDS )); then
    continue
  fi

  if ! acquire_lock; then
    continue
  fi

  {
    echo "[$(date --iso-8601=seconds)] Stable change set detected."

    if [[ -z "$(status_snapshot)" ]]; then
      echo "[$(date --iso-8601=seconds)] Nothing to commit."
      release_lock
      continue
    fi

    git -C "${ROOT_DIR}" add -A

    if git -C "${ROOT_DIR}" diff --cached --quiet; then
      echo "[$(date --iso-8601=seconds)] No staged diff after add."
      release_lock
      continue
    fi

    commit_message="auto: sync changes $(date --iso-8601=seconds)"
    git -C "${ROOT_DIR}" commit -m "${commit_message}"
    GIT_TERMINAL_PROMPT=0 git -C "${ROOT_DIR}" push origin "${BRANCH}"
    echo "[$(date --iso-8601=seconds)] Pushed ${BRANCH}."
  } >> "${LOG_FILE}" 2>&1 || true

  release_lock
  last_snapshot="$(status_snapshot)"
  last_change_epoch="$(date +%s)"
done
