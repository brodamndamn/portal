#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
NGINX_AVAILABLE="/etc/nginx/sites-available/resume-projects"
NGINX_ENABLED="/etc/nginx/sites-enabled/resume-projects"
BACKUP_DIR="/var/backups/resume-projects/nginx-$(date +%Y%m%d-%H%M%S)"
HAD_OLD_CONFIG=0
ROLLBACK_ARMED=0
ESCAPED_WEB_ROOT=""
declare -a MOVED_SITES=()
rollback() {
  local exit_code=$?
  trap - ERR
  if [[ "${ROLLBACK_ARMED}" -eq 1 ]]; then
    echo "Nginx 配置校验失败，正在恢复旧配置……" >&2
    rm -f "${NGINX_ENABLED}"
    if [[ "${HAD_OLD_CONFIG}" -eq 1 ]]; then cp -a "${BACKUP_DIR}/resume-projects.conf" "${NGINX_AVAILABLE}"; ln -s "${NGINX_AVAILABLE}" "${NGINX_ENABLED}"; else rm -f "${NGINX_AVAILABLE}"; fi
    for site in "${MOVED_SITES[@]}"; do mv "${BACKUP_DIR}/sites-enabled/$(basename "${site}")" "${site}"; done
    nginx -t && systemctl reload nginx || true
  fi
  exit "${exit_code}"
}
require_root; require_command nginx; require_command systemctl
require_file "${SCRIPT_DIR}/nginx/resume-projects.conf"
trap rollback ERR
ESCAPED_WEB_ROOT="$(printf '%s' "${WEB_ROOT}" | sed 's/[&|]/\\&/g')"
declare -a CONFLICTS=()
shopt -s nullglob
for site in /etc/nginx/sites-enabled/*; do
  [[ "${site}" == "${NGINX_ENABLED}" ]] && continue
  if grep -Eq 'default_server|/var/www/isaac|127\.0\.0\.1:8000|/var/www/research|127\.0\.0\.1:8001' "${site}"; then CONFLICTS+=("${site}"); fi
done
shopt -u nullglob
if (( ${#CONFLICTS[@]} > 0 )) && [[ "${REPLACE_CONFLICTING_NGINX:-0}" != "1" ]]; then
  echo "检测到可能与双项目路由冲突的 Nginx 站点：" >&2; printf '  - %s\n' "${CONFLICTS[@]}" >&2
  echo "确认替换后，使用 sudo REPLACE_CONFLICTING_NGINX=1 bash portal/deploy/install-nginx.sh 重新执行。" >&2; exit 1
fi
install -d -m 0755 "${BACKUP_DIR}/sites-enabled" /etc/nginx/sites-available /etc/nginx/sites-enabled
if [[ -f "${NGINX_AVAILABLE}" ]]; then cp -a "${NGINX_AVAILABLE}" "${BACKUP_DIR}/resume-projects.conf"; HAD_OLD_CONFIG=1; fi
ROLLBACK_ARMED=1
for site in "${CONFLICTS[@]}"; do mv "${site}" "${BACKUP_DIR}/sites-enabled/"; MOVED_SITES+=("${site}"); done
sed "s|/var/www|${ESCAPED_WEB_ROOT}|g" "${SCRIPT_DIR}/nginx/resume-projects.conf" > "${NGINX_AVAILABLE}"
chmod 0644 "${NGINX_AVAILABLE}"; rm -f "${NGINX_ENABLED}"; ln -s "${NGINX_AVAILABLE}" "${NGINX_ENABLED}"
nginx -t; systemctl reload nginx; ROLLBACK_ARMED=0
echo "统一 Nginx 路由已安装，旧配置备份：${BACKUP_DIR}"
