#!/usr/bin/env bash
set -Eeuo pipefail
require_command() { command -v "$1" >/dev/null 2>&1 || { echo "缺少命令：$1" >&2; exit 1; }; }
require_command curl; require_command systemctl
systemctl is-active --quiet nginx
systemctl is-active --quiet isaac-backend
systemctl is-active --quiet researchflow
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/ >/dev/null
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/isaac/ >/dev/null
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/research/ >/dev/null
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/isaac/api/v1/health >/dev/null
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/research/api/health/live >/dev/null
echo "健康检查通过：Portal、ISAAC、ResearchFlow、两个 API 与 systemd 服务均正常。"
