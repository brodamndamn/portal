# 统一部署脚本

脚本位于 Portal 仓库中，但默认管理三个并列仓库所在的共同目录：`/opt/resume-projects`。

| 脚本 | 用途 |
| --- | --- |
| `deploy-portal.sh` | 同步 Portal 静态文件到 `/var/www/portal` |
| `deploy-isaac.sh` | 构建 ISAAC、迁移数据库并重启 `isaac-backend` |
| `build-researchflow-frontend.ps1` | 在 Windows 本机打包并上传 ResearchFlow 前端产物 |
| `deploy-researchflow.sh` | 默认跳过前端构建，更新 ResearchFlow 后端并重启 `researchflow` |
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

## 2 核 2GB 服务器：ResearchFlow 更新流程

不要在服务器构建 ResearchFlow 前端。请在 Windows 本机运行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\\暑假task\\resume_projects\\portal\\deploy\\build-researchflow-frontend.ps1" -Server "<服务器用户>@<服务器IP>"
```

上传完成后，在服务器执行：

```bash
sudo rsync -a --delete /tmp/researchflow-dist/ /var/www/research/
sudo SKIP_RESEARCHFLOW_FRONTEND_BUILD=1 bash /opt/resume-projects/portal/deploy/deploy-researchflow.sh
```

只有服务器扩容且确有需要时，才显式传入 `SKIP_RESEARCHFLOW_FRONTEND_BUILD=0` 让服务器自行构建。

## 本机构建、服务器不构建前端

2 核 2GB 服务器使用以下流程。它不会复制或修改服务器中的 `.env`：

1. Windows 本机构建并上传三个静态站点：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\暑假task\resume_projects\portal\deploy\build-and-upload-frontends.ps1" -Server "admin@47.103.69.8"
```

2. 先将三个仓库的后端源码更新到服务器后，在服务器执行：

```bash
sudo bash /opt/resume-projects/portal/deploy/deploy-prebuilt-all.sh
```

首次替换原 ISAAC 根路由时，命令前加上 `REPLACE_CONFLICTING_NGINX=1`。`deploy-prebuilt-all.sh` 只同步已上传的静态产物；ISAAC 和 ResearchFlow 都默认跳过服务器前端构建。