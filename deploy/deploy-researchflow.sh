#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

RESEARCH_ROOT="${PROJECT_ROOT}/agents_project"
FRONTEND_DIR="${RESEARCH_ROOT}/frontend"
BACKEND_DIR="${RESEARCH_ROOT}/backend"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"
SKIP_RESEARCHFLOW_FRONTEND_BUILD="${SKIP_RESEARCHFLOW_FRONTEND_BUILD:-1}"

require_root
require_command "${PYTHON_BIN}"
require_command rsync
require_file "${FRONTEND_DIR}/pnpm-lock.yaml"
require_file "${BACKEND_DIR}/pyproject.toml"
require_env_file "${BACKEND_DIR}/.env"

if [[ "${SKIP_RESEARCHFLOW_FRONTEND_BUILD}" == "1" ]]; then
  echo "跳过服务器 ResearchFlow 前端构建：使用已上传的 ${WEB_ROOT}/research 静态文件。"
  require_file "${WEB_ROOT}/research/index.html"
else
  require_command pnpm
  echo "构建 ResearchFlow 前端……"
  ( cd "${FRONTEND_DIR}"; pnpm install --frozen-lockfile; pnpm build )
  require_file "${FRONTEND_DIR}/dist/index.html"
fi

echo "安装 ResearchFlow 后端依赖……"
(
  cd "${BACKEND_DIR}"
  "${PYTHON_BIN}" -m venv .venv
  .venv/bin/python -m pip install --upgrade pip
  .venv/bin/python -m pip install .
)

install -d -o "${APP_USER}" -g "${APP_GROUP}" -m 0750 "${BACKEND_DIR}/data"
if [[ "${SKIP_RESEARCHFLOW_FRONTEND_BUILD}" != "1" ]]; then
  sync_static "${FRONTEND_DIR}/dist" "${WEB_ROOT}/research"
fi
install_service "${SCRIPT_DIR}/systemd/researchflow.service" "researchflow"

echo "ResearchFlow 已部署：静态文件 ${WEB_ROOT}/research，后端 127.0.0.1:8001"