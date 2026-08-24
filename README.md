# 双项目引导页与统一部署

完整服务器部署请阅读 [DEPLOYMENT.md](DEPLOYMENT.md)。

`portal/` 是独立静态入口，不依赖 ISAAC 或 ResearchFlow 的前端构建。部署后的公开路径如下：

| 路径 | 内容 |
|---|---|
| `/` | 本引导页 |
| `/isaac/` | ISAAC 玩家社区 |
| `/research/` | ResearchFlow 深度研究 Agent |

## 服务器目录

- 引导页：`/var/www/portal`
- ISAAC 前端：`/var/www/isaac`
- ResearchFlow 前端：`/var/www/research`
- 统一 Nginx 配置：`/etc/nginx/sites-available/resume-projects`

## 部署前提

- ISAAC 后端监听 `127.0.0.1:8000`。
- ResearchFlow 后端监听 `127.0.0.1:8001`。
- ISAAC 已执行 `npm run build`，产物位于 `ISAAC/frontend/dist/`。
- ResearchFlow 已执行 `pnpm build`，产物位于 `agents_project/frontend/dist/`。
- 在服务器共同父目录执行 `sudo bash portal/deploy/deploy.sh`。

脚本先把三个站点复制到临时目录，再备份现有静态目录、Nginx 配置和会冲突的旧站点链接。统一配置第一次通过 `nginx -t` 后才替换静态文件，任一步失败会自动回滚；第二次检查通过后才 reload Nginx。它不会重启 MySQL，也不会修改两个 FastAPI 服务和数据库。

## 上线后检查

```bash
curl -I http://127.0.0.1/
curl -I http://127.0.0.1/isaac/
curl http://127.0.0.1/isaac/api/v1/health
curl http://127.0.0.1/research/api/health/live
```

直接刷新 `/isaac/items/1`、`/isaac/guides/1` 和已有的 `/research/run/{id}`，均应由各自 SPA 的 `index.html` 接管。

旧 `/api/` 和 `/uploads/` 暂时保留给 ISAAC；确认新版前端和浏览器缓存稳定后，可以单独移除旧 `/api/` 代理。旧 `/uploads/` 需长期保留，以兼容数据库中的历史攻略图片地址。
