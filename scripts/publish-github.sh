#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run from inside a Git repository." >&2
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Remote 'origin' is not configured." >&2
  echo "Run: git remote add origin <URL_DU_REPO_GITHUB>" >&2
  exit 1
fi

remote_url="$(git remote get-url origin)"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

echo "Publishing branch '${current_branch}' to '${remote_url}'..."

if [[ -n "$(git status --short)" ]]; then
  echo "Working tree is not clean." >&2
  echo "Only committed changes will be published to GitHub." >&2
fi

if ! ssh_output="$(GIT_TERMINAL_PROMPT=0 git ls-remote origin 2>&1)" ; then
  echo "GitHub authentication failed for remote '${remote_url}'." >&2

  if [[ "${remote_url}" == git@github.com:* ]]; then
    echo "${ssh_output}" >&2
    echo "Check that the repository exists and that your GitHub account has write access to it." >&2
  else
    echo "If you use HTTPS, configure a Personal Access Token or authenticate with GitHub CLI before retrying." >&2
  fi

  exit 1
fi

GIT_TERMINAL_PROMPT=0 git push -u origin "${current_branch}"
