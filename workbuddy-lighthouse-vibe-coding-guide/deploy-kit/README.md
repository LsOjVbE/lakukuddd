# deploy-kit · 部署工具包

配合《从 WorkBuddy 到云端 · 动手实践指南》使用。
把本目录整体复制进你的项目根目录，即可按指南步骤直接开工。

## 文件说明

| 文件 | 用途 | 放在哪 |
|---|---|---|
| `server_info.md` | 部署目标事实来源，AI 每次部署前先读它 | 项目目录 |
| `init-lighthouse.sh` | 服务器一次性初始化（加固 / Docker / Swap / 防火墙） | 上传到服务器执行 |
| `Dockerfile` | 应用容器构建定义（非 root + 健康检查） | 项目根目录 |
| `docker-compose.yml` | 服务编排（端口绑回环地址 + 数据卷） | 项目根目录 |
| `.env.example` | 环境变量模板，复制为 `.env` 后填真实值 | 项目根目录 |
| `nginx-app.conf` | 反向代理配置 | 服务器 `/etc/nginx/conf.d/` |
| `deploy.sh` | 一键更新脚本，内置健康检查与回滚提示 | 服务器 `/opt/<app>/` |
| `prompts.md` | 本指南全部提示词模板汇总 | 随手可查 |

## 使用顺序

```bash
# 1) 本地：补全部署目标信息
vim deploy-kit/server_info.md

# 2) 服务器：首次初始化（需 sudo）
scp -i ~/.ssh/lighthouse_key.pem deploy-kit/init-lighthouse.sh deployer@IP:~/
ssh  -i ~/.ssh/lighthouse_key.pem deployer@IP
sudo bash init-lighthouse.sh

# 3) 服务器：放好应用
sudo mkdir -p /opt/my-vibe-app && sudo chown deployer:deployer /opt/my-vibe-app
git clone <你的仓库> /opt/my-vibe-app
cp .env.example .env && vim .env
cp deploy.sh /opt/my-vibe-app/ && chmod +x /opt/my-vibe-app/deploy.sh

# 4) 后续每次更新
bash /opt/my-vibe-app/deploy.sh
```

## 安全提醒

- `.env` 与私钥文件必须写入 `.gitignore`，绝不提交。
- `server_info.md` 只写私钥**路径**，不写私钥内容。
- 面板端口（Coolify 8000 / Dokploy 3000）请优先通过 SSH 隧道访问，不要长期对公网开放。
- 关闭 SSH 密码登录前，务必先另开一个终端验证密钥登录成功。
