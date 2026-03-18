#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_VENV="/opt/gitops-tooling"

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "[1/7] Installing base packages..."
${SUDO} dnf install -y dnf-plugins-core git curl wget unzip jq make python3 python3-pip

echo "[2/7] Configuring Docker repository..."
${SUDO} dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true

echo "[3/7] Installing Docker..."
${SUDO} dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
${SUDO} systemctl enable --now docker

echo "[4/7] Configuring HashiCorp repository..."
${SUDO} curl -fsSL https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo

echo "[5/7] Installing Terraform and Ansible..."
${SUDO} dnf install -y terraform ansible-core

echo "[6/7] Installing Checkov..."
${SUDO} python3 -m venv "${TOOLS_VENV}"
${SUDO} "${TOOLS_VENV}/bin/pip" install --upgrade pip
${SUDO} "${TOOLS_VENV}/bin/pip" install checkov docker requests
${SUDO} ln -sf "${TOOLS_VENV}/bin/checkov" /usr/local/bin/checkov

echo "[7/7] Installing Trivy and Ansible collection..."
cat <<'EOF' | ${SUDO} tee /etc/yum.repos.d/trivy.repo >/dev/null
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
enabled=1
gpgcheck=0
EOF
${SUDO} dnf install -y trivy

ansible-galaxy collection install -r "${ROOT_DIR}/configuration/ansible/requirements.yml" || true

echo "Installation complete."
echo "Add your user to the docker group if needed: sudo usermod -aG docker <user>"
