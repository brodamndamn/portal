# 双项目部署说明

本仓库保存 Portal 与三个仓库的统一部署脚本。公网路径为：`/`（Portal）、`/isaac/`（ISAAC）及 `/research/`（ResearchFlow）。

## 服务器目录

三个仓库应位于同一目录：

```text
/opt/resume-projects/
├── portal/
├── ISAAC/
└── agents_project/
```

首次部署前安装基础工具，并启用 Node 的 Corepack：

```bash
sudo apt update
sudo apt install -y nginx rsync curl git python3 python3-venv python3-pip mysql-client
corepack enable
corepack prepare pnpm@11.19.0 --activate
```

将 `portal/deploy/env/` 中的模板复制到两个后端的 `.env` 后填写真实值。ISAAC 服务器 MySQL 使用 `DB_PORT=3306`，不要沿用本机开发端口 `3307`；ResearchFlow 需填写 DeepSeek、Tavily 与 HMAC 密钥。

安装路由并首次全量部署：

```bash
cd /opt/resume-projects
sudo REPLACE_CONFLICTING_NGINX=1 bash portal/deploy/install-nginx.sh
sudo bash portal/deploy/deploy-all.sh
```

日常更新代码后可执行：

```bash
cd /opt/resume-projects
sudo bash portal/deploy/deploy-all.sh
```

脚本会构建两个前端、同步静态文件、重启两个 FastAPI systemd 服务并运行健康检查；不会重启 MySQL。Nginx 在校验通过后才会 reload。旧 `/api/` 与 `/uploads/` 兼容路由保留给 ISAAC 历史数据。
