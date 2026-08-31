#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

UPLOAD_ROOT="${PREBUILT_UPLOAD_ROOT:-/tmp/resume-frontends}"

require_root
require_command rsync
for site in portal isaac research; do
  require_file "${UPLOAD_ROOT}/${site}/index.html"
done

sync_static "${UPLOAD_ROOT}/portal" "${WEB_ROOT}/portal"
sync_static "${UPLOAD_ROOT}/isaac" "${WEB_ROOT}/isaac"
sync_static "${UPLOAD_ROOT}/research" "${WEB_ROOT}/research"

echo "三个本机构建的静态站点已同步到 ${WEB_ROOT}。"