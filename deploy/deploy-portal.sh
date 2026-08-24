#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
require_root
require_command rsync
require_file "${PROJECT_ROOT}/portal/index.html"
require_file "${PROJECT_ROOT}/portal/styles.css"
sync_static "${PROJECT_ROOT}/portal" "${WEB_ROOT}/portal"
echo "Portal 已部署到 ${WEB_ROOT}/portal"
