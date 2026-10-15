# 部署目标 · 唯一事实来源

> 把这份文件放进项目目录（建议 `deploy-kit/server_info.md`），
> 所有部署指令都要求 AI 先读它，避免记错 IP、搞混环境。
>
> ⚠️ 本文件只写私钥的**路径**，绝不写入私钥内容。
> 私钥文件请加入 `.gitignore`。

CLOUD=腾讯云 Lighthouse
REGION=ap-shanghai
PUBLIC_IP=123.45.67.89

# 登录
SSH_USER=deployer
SSH_KEY=~/.ssh/lighthouse_key.pem
SSH_PORT=22

# 应用
APP_NAME=my-vibe-app
APP_DIR=/opt/my-vibe-app
APP_PORT=3000
HEALTH_PATH=/healthz

# 入口
DOMAIN=app.example.com
PUBLIC_PORTS=80,443
TLS=Let's Encrypt (certbot / 面板自动签发)

# 平台
PAAS=Coolify            # Coolify | Dokploy | 宝塔 | Portainer | none
NGINX_CONF=/etc/nginx/conf.d/app.conf
DATA_VOLUME=./data

# 运维
BACKUP=S3/COS 定时同步 + 实例快照
OWNER=你的名字
EXPIRE_DATE=YYYY-MM-DD  # 实例到期日，到期前处理，避免转按量计费
