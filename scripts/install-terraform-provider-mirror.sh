#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROVIDER_VERSION="${PROVIDER_VERSION:-3.9.0}"

case "$(uname -m)" in
  x86_64)
    TARGET="linux_amd64"
    ;;
  aarch64 | arm64)
    TARGET="linux_arm64"
    ;;
  armv7l)
    TARGET="linux_arm"
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

MIRROR_DIR="${ROOT_DIR}/terraform.d/plugins/registry.terraform.io/kreuzwerker/docker"
PACKAGE_NAME="terraform-provider-docker_${PROVIDER_VERSION}_${TARGET}.zip"
PACKAGE_PATH="${MIRROR_DIR}/${PACKAGE_NAME}"
PACKAGE_URL="https://github.com/kreuzwerker/terraform-provider-docker/releases/download/v${PROVIDER_VERSION}/${PACKAGE_NAME}"

mkdir -p "${MIRROR_DIR}"

if [[ -f "${PACKAGE_PATH}" ]]; then
  echo "Terraform provider mirror already present: ${PACKAGE_PATH}"
else
  echo "Downloading Terraform Docker provider ${PROVIDER_VERSION} for ${TARGET}..."
  curl -fsSL "${PACKAGE_URL}" -o "${PACKAGE_PATH}"
  echo "Provider mirror stored at ${PACKAGE_PATH}"
fi

cat > "${ROOT_DIR}/terraform.rc" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "${ROOT_DIR}/terraform.d/plugins"
    include = ["registry.terraform.io/kreuzwerker/docker"]
  }

  direct {
    exclude = ["registry.terraform.io/kreuzwerker/docker"]
  }
}
EOF

echo "Terraform CLI config written to ${ROOT_DIR}/terraform.rc"
