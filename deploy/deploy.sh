#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/var/backups/resume-projects/${TIMESTAMP}"
STAGE_DIR="$(mktemp -d /var/tmp/resume-projects.XXXXXX)"
NGINX_AVAILABLE="/etc/nginx/sites-available/resume-projects"
NGINX_ENABLED="/etc/nginx/sites-enabled/resume-projects"
ROLLBACK_ARMED=0

cleanup() {
  rm -rf "${STAGE_DIR}"
}

restore_static_dir() {
  local name="$1"
  local target="/var/www/${name}"
  if [[ -f "${BACKUP_DIR}/static/${name}.missing" ]]; then
    rm -rf "${target}"
    return
  fi
  install -d "${target}"
  rsync -a --delete "${BACKUP_DIR}/static/${name}/" "${target}/"
}

rollback() {
  local exit_code=$?
  trap - ERR
  if [[ "${ROLLBACK_ARMED}" -eq 1 ]]; then
    echo "部署失败，正在恢复旧版本……" >&2
    restore_static_dir portal
    restore_static_dir isaac
    restore_static_dir research

    if [[ -f "${BACKUP_DIR}/nginx-config.missing" ]]; then
      rm -f "${NGINX_AVAILABLE}"
    else
      cp -a "${BACKUP_DIR}/nginx-resume-projects.conf" "${NGINX_AVAILABLE}"
    fi

    rm -f "${NGINX_ENABLED}"
    cp -a "${BACKUP_DIR}/enabled/." /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx || true
  fi
  exit "${exit_code}"
}

trap cleanup EXIT
trap rollback ERR

if [[ ! -f "${WORKSPACE_DIR}/ISAAC/frontend/dist/index.html" ]]; then
  echo "缺少 ISAAC 构建产物，请先在 ISAAC/frontend 执行 npm run build。" >&2
  exit 1
fi

if [[ ! -f "${WORKSPACE_DIR}/agents_project/frontend/dist/index.html" ]]; then
  echo "缺少 ResearchFlow 构建产物，请先在 agents_project/frontend 执行 pnpm build。" >&2
  exit 1
fi

install -d "${STAGE_DIR}/portal" "${STAGE_DIR}/isaac" "${STAGE_DIR}/research"
rsync -a --delete "${WORKSPACE_DIR}/ISAAC/frontend/dist/" "${STAGE_DIR}/isaac/"
rsync -a --delete "${WORKSPACE_DIR}/agents_project/frontend/dist/" "${STAGE_DIR}/research/"
rsync -a --delete --exclude deploy/ "${WORKSPACE_DIR}/portal/" "${STAGE_DIR}/portal/"

install -d "${BACKUP_DIR}/static" "${BACKUP_DIR}/enabled" /var/www
for name in portal isaac research; do
  target="/var/www/${name}"
  if [[ -d "${target}" ]]; then
    install -d "${BACKUP_DIR}/static/${name}"
    rsync -a "${target}/" "${BACKUP_DIR}/static/${name}/"
  else
    touch "${BACKUP_DIR}/static/${name}.missing"
  fi
done

if [[ -f "${NGINX_AVAILABLE}" ]]; then
  cp -a "${NGINX_AVAILABLE}" "${BACKUP_DIR}/nginx-resume-projects.conf"
else
  touch "${BACKUP_DIR}/nginx-config.missing"
fi

ROLLBACK_ARMED=1
shopt -s nullglob
for enabled in /etc/nginx/sites-enabled/*; do
  if [[ "${enabled}" == "${NGINX_ENABLED}" ]] || \
     grep -Eq 'default_server|/var/www/isaac|127\.0\.0\.1:8000|/var/www/research|127\.0\.0\.1:8001' "${enabled}"; then
    cp -a "${enabled}" "${BACKUP_DIR}/enabled/"
    rm -f "${enabled}"
  fi
done
shopt -u nullglob

install -m 0644 "${SCRIPT_DIR}/nginx-resume-projects.conf" "${NGINX_AVAILABLE}"
ln -s "${NGINX_AVAILABLE}" "${NGINX_ENABLED}"
nginx -t

for name in portal isaac research; do
  install -d "/var/www/${name}"
  rsync -a --delete "${STAGE_DIR}/${name}/" "/var/www/${name}/"
done
chown -R www-data:www-data /var/www/portal /var/www/isaac /var/www/research

nginx -t
systemctl reload nginx
ROLLBACK_ARMED=0

echo "部署完成。备份目录：${BACKUP_DIR}"
