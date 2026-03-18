#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${ROOT_DIR}/reports/security"
mkdir -p "${REPORT_DIR}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Starting Security Scan Pipeline ===${NC}"

if command -v checkov >/dev/null 2>&1; then
  echo -e "${YELLOW}[1/4] Scanning Terraform files with Checkov...${NC}"
  checkov -d "${ROOT_DIR}/infrastructure/terraform" \
    --framework terraform \
    --output json \
    --quiet > "${REPORT_DIR}/security-report-terraform.json" || true

  echo -e "${YELLOW}[2/4] Scanning Ansible files with Checkov...${NC}"
  checkov -d "${ROOT_DIR}/configuration/ansible" \
    --framework ansible \
    --output json \
    --quiet > "${REPORT_DIR}/security-report-ansible.json" || true

  echo -e "${YELLOW}[3/4] Scanning Dockerfiles with Checkov...${NC}"
  checkov -d "${ROOT_DIR}/application" \
    --framework dockerfile \
    --output json \
    --quiet > "${REPORT_DIR}/security-report-docker.json" || true
else
  echo -e "${RED}Checkov is not installed. Skipping IaC scans.${NC}"
fi

if command -v trivy >/dev/null 2>&1; then
  echo -e "${YELLOW}[4/4] Scanning images with Trivy...${NC}"
  for image in "gitops-monitoring-app:local" "prom/prometheus:latest" "grafana/grafana:latest"; do
    safe_name="$(echo "${image}" | tr '/:' '__')"
    trivy image \
      --severity HIGH,CRITICAL \
      --format json \
      --output "${REPORT_DIR}/trivy-${safe_name}.json" \
      "${image}" || true
  done
else
  echo -e "${RED}Trivy is not installed. Skipping image scans.${NC}"
fi

critical_count="$(grep -R -c "CRITICAL" "${REPORT_DIR}" 2>/dev/null | awk -F: '{sum += $2} END {print sum + 0}')"

echo -e "${GREEN}Reports generated under ${REPORT_DIR}${NC}"

if [[ "${critical_count}" -gt 0 ]]; then
  echo -e "${RED}WARNING: ${critical_count} critical findings detected.${NC}"
  exit 1
fi

echo -e "${GREEN}No critical findings detected in generated reports.${NC}"
