#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== GitOps Validation ==="

if command -v git >/dev/null 2>&1 && [[ -d "${ROOT_DIR}/.git" ]]; then
  echo "1. Checking Git status..."
  if [[ -z "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
    echo "   Working directory clean"
  else
    echo "   Uncommitted changes detected"
    git -C "${ROOT_DIR}" status --short
  fi
else
  echo "1. Git not initialized yet in ${ROOT_DIR}"
fi

if command -v terraform >/dev/null 2>&1; then
  echo "2. Validating Terraform..."
  "${ROOT_DIR}/scripts/install-terraform-provider-mirror.sh"
  export TF_CLI_CONFIG_FILE="${ROOT_DIR}/terraform.rc"
  terraform -chdir="${ROOT_DIR}/infrastructure/terraform" fmt -check -recursive
  terraform -chdir="${ROOT_DIR}/infrastructure/terraform" init -backend=false
  terraform -chdir="${ROOT_DIR}/infrastructure/terraform" validate
else
  echo "2. Terraform not installed"
fi

if command -v ansible-playbook >/dev/null 2>&1; then
  echo "3. Validating Ansible..."
  ansible-playbook -i "${ROOT_DIR}/configuration/ansible/inventory.yml" \
    "${ROOT_DIR}/configuration/ansible/playbook.yml" \
    --syntax-check
else
  echo "3. Ansible not installed"
fi

if command -v docker >/dev/null 2>&1; then
  echo "4. Checking Docker resources..."
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
  docker network ls | grep gitops-monitoring || true
  docker volume ls | grep -E "prometheus|grafana" || true
else
  echo "4. Docker not installed"
fi

echo "=== Validation Complete ==="
