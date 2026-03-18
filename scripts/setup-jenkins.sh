#!/usr/bin/env bash

set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-Admin123!2026}"
JOB_NAME="${JOB_NAME:-gitops-local-pipeline}"

echo "Waiting for Jenkins at ${JENKINS_URL}..."
until curl -fsS "${JENKINS_URL}/login" >/dev/null; do
  sleep 5
done

echo "Jenkins is reachable."
echo "User: ${JENKINS_USER}"
echo "Password: ${JENKINS_PASSWORD}"

if curl -fsS -u "${JENKINS_USER}:${JENKINS_PASSWORD}" "${JENKINS_URL}/job/${JOB_NAME}/api/json" >/dev/null 2>&1; then
  echo "Job '${JOB_NAME}' is configured."
else
  echo "Job '${JOB_NAME}' is not reachable yet. Check Jenkins logs if needed."
fi

