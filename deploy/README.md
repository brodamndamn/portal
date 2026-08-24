# 统一部署脚本

脚本位于 Portal 仓库中，但默认管理三个并列仓库所在的共同目录：`/opt/resume-projects`。

| 脚本 | 用途 |
| --- | --- |
| `deploy-portal.sh` | 同步 Portal 静态文件到 `/var/www/portal` |
| `deploy-isaac.sh` | 构建 ISAAC、迁移数据库并重启 `isaac-backend` |
| `deploy-researchflow.sh` | 构建 ResearchFlow 并重启 `researchflow` |
| `install-nginx.sh` | 安装统一 Nginx 路由 |
| `deploy-all.sh` | 依次部署全部服务 |
| `verify.sh` | 健康检查 |

服务器目录必须是：

```text
/opt/resume-projects/
├── portal/
├── ISAAC/
└── agents_project/
```

第一次安装 Nginx 时，如果发现旧 ISAAC 根路由站点，请显式确认：

```bash
cd /opt/resume-projects
sudo REPLACE_CONFLICTING_NGINX=1 bash portal/deploy/install-nginx.sh
```

完整部署请阅读仓库根目录的 [DEPLOYMENT.md](../DEPLOYMENT.md)。
