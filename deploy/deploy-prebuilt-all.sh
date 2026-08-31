#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
bash "${SCRIPT_DIR}/deploy-prebuilt-static.sh"
SKIP_ISAAC_FRONTEND_BUILD=1 bash "${SCRIPT_DIR}/deploy-isaac.sh"
SKIP_RESEARCHFLOW_FRONTEND_BUILD=1 bash "${SCRIPT_DIR}/deploy-researchflow.sh"
bash "${SCRIPT_DIR}/install-nginx.sh"
bash "${SCRIPT_DIR}/verify.sh"

echo "部署完成：三个静态站点均来自本机构建，服务器未执行前端构建。"