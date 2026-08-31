#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
RESEARCH_ROOT="${PROJECT_ROOT}/agents_project"
FRONTEND_DIR="${RESEARCH_ROOT}/frontend"
BACKEND_DIR="${RESEARCH_ROOT}/backend"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"
# 默认将构建绑定到单核，并保留足够内存给两个后端与 Nginx。
# 如服务器扩容，可在执行时覆盖 BUILD_CPU 与 NODE_BUILD_HEAP_MB。
BUILD_CPU="${BUILD_CPU:-0}"
NODE_BUILD_HEAP_MB="${NODE_BUILD_HEAP_MB:-384}"
require_root
require_command pnpm; require_command "${PYTHON_BIN}"; require_command rsync; require_command taskset
require_file "${FRONTEND_DIR}/pnpm-lock.yaml"
require_file "${BACKEND_DIR}/pyproject.toml"
require_env_file "${BACKEND_DIR}/.env"
echo "构建 ResearchFlow 前端……"
# 2 核 2G 服务器在 pnpm 的默认并发下载、解压时可能被内存压力拖死。
# 构建只在部署时执行，优先保证稳定性而不是首次安装速度。
(
  cd "${FRONTEND_DIR}"
  pnpm install --frozen-lockfile --network-concurrency=1 --child-concurrency=1 --reporter=append-only
  # 2C2G 服务器不执行开发期 TypeScript 全量检查；该检查应在本机或 CI 完成。
  # 仅使用单核运行 Vite 打包，Node 堆限制为 384MB，避免构建导致实例失联。
  taskset --cpu-list "${BUILD_CPU}" env \
    UV_THREADPOOL_SIZE=1 \
    NODE_OPTIONS="--max-old-space-size=${NODE_BUILD_HEAP_MB}" \
    pnpm exec vite build
)
require_file "${FRONTEND_DIR}/dist/index.html"
echo "安装 ResearchFlow 后端依赖……"
( cd "${BACKEND_DIR}"; "${PYTHON_BIN}" -m venv .venv; .venv/bin/python -m pip install --upgrade pip; .venv/bin/python -m pip install . )
install -d -o "${APP_USER}" -g "${APP_GROUP}" -m 0750 "${BACKEND_DIR}/data"
chown root:"${APP_GROUP}" "${BACKEND_DIR}/.env"; chmod 0640 "${BACKEND_DIR}/.env"
sync_static "${FRONTEND_DIR}/dist" "${WEB_ROOT}/research"
install_service "${SCRIPT_DIR}/systemd/researchflow.service" "researchflow"
echo "ResearchFlow 已部署：静态文件 ${WEB_ROOT}/research，后端 127.0.0.1:8001"
