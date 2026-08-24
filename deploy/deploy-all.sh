#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
require_root
bash "${SCRIPT_DIR}/deploy-portal.sh"
bash "${SCRIPT_DIR}/deploy-isaac.sh"
bash "${SCRIPT_DIR}/deploy-researchflow.sh"
bash "${SCRIPT_DIR}/install-nginx.sh"
bash "${SCRIPT_DIR}/verify.sh"
echo "三个入口与两个后端均已部署完成。"
