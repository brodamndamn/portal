#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
ISAAC_ROOT="${PROJECT_ROOT}/ISAAC"
FRONTEND_DIR="${ISAAC_ROOT}/frontend"
BACKEND_DIR="${ISAAC_ROOT}/backend"
require_root
require_command npm; require_command python3; require_command rsync
require_file "${FRONTEND_DIR}/package-lock.json"
require_file "${BACKEND_DIR}/requirements.txt"
require_file "${BACKEND_DIR}/alembic.ini"
require_env_file "${BACKEND_DIR}/.env"
echo "构建 ISAAC 前端……"
( cd "${FRONTEND_DIR}"; npm ci; npm run build )
require_file "${FRONTEND_DIR}/dist/index.html"
echo "安装 ISAAC 后端依赖并执行数据库迁移……"
( cd "${BACKEND_DIR}"; python3 -m venv .venv; .venv/bin/python -m pip install --upgrade pip; .venv/bin/python -m pip install -r requirements.txt; .venv/bin/alembic upgrade head )
install -d -o "${APP_USER}" -g "${APP_GROUP}" -m 0750 "${BACKEND_DIR}/uploads"
chown root:"${APP_GROUP}" "${BACKEND_DIR}/.env"; chmod 0640 "${BACKEND_DIR}/.env"
sync_static "${FRONTEND_DIR}/dist" "${WEB_ROOT}/isaac"
install_service "${SCRIPT_DIR}/systemd/isaac-backend.service" "isaac-backend"
echo "ISAAC 已部署：静态文件 ${WEB_ROOT}/isaac，后端 127.0.0.1:8000"
