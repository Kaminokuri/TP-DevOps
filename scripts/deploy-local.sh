#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${ROOT_DIR}/jenkins_home"
mkdir -p "${ROOT_DIR}/reports/security"

terraform -chdir="${ROOT_DIR}/infrastructure/terraform" init
terraform -chdir="${ROOT_DIR}/infrastructure/terraform" apply -auto-approve

ansible-galaxy collection install -r "${ROOT_DIR}/configuration/ansible/requirements.yml"
ansible-playbook -i "${ROOT_DIR}/configuration/ansible/inventory.yml" "${ROOT_DIR}/configuration/ansible/playbook.yml"

"${ROOT_DIR}/scripts/setup-jenkins.sh"

echo "Deployment complete."

