#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 本脚本存放于 /opt/resume-projects/portal/deploy/lib，因此上三级是三个仓库的共同目录。
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
WEB_ROOT="${WEB_ROOT:-/var/www}"
APP_USER="${APP_USER:-www-data}"
APP_GROUP="${APP_GROUP:-www-data}"

require_root() { [[ "${EUID}" -eq 0 ]] || { echo "请使用 sudo bash 执行部署脚本。" >&2; exit 1; }; }
require_command() { command -v "$1" >/dev/null 2>&1 || { echo "缺少命令：$1" >&2; exit 1; }; }
require_file() { [[ -f "$1" ]] || { echo "缺少文件：$1" >&2; exit 1; }; }
require_env_file() { [[ -f "$1" ]] || { echo "缺少环境变量文件：$1" >&2; echo "请先从 portal/deploy/env/ 对应模板复制为 .env 并填写真实值。" >&2; exit 1; }; }

sync_static() {
  local source_dir="$1" target_dir="$2"
  install -d -m 0755 "${target_dir}"
  rsync -a --delete --exclude '.git/' --exclude 'deploy/' "${source_dir}/" "${target_dir}/"
  chown -R "${APP_USER}:${APP_GROUP}" "${target_dir}"
}

install_service() {
  local source_file="$1" service_name="$2" escaped_project_root
  escaped_project_root="$(printf '%s' "${PROJECT_ROOT}" | sed 's/[&|]/\\&/g')"
  sed "s|/opt/resume-projects|${escaped_project_root}|g" "${source_file}" > "/etc/systemd/system/${service_name}.service"
  chmod 0644 "/etc/systemd/system/${service_name}.service"
  systemctl daemon-reload
  systemctl enable "${service_name}.service"
  systemctl restart "${service_name}.service"
}
