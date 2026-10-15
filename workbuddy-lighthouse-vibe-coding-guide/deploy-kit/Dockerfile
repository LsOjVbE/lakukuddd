# ============================================================
# Node.js 应用示例 Dockerfile
# 要点：alpine 精简基础镜像 · 非 root 运行 · 内置健康检查
# ============================================================
FROM node:20-alpine

# 创建非 root 运行用户
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

# 先复制依赖清单，利用 Docker 层缓存加速重复构建
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# 再复制源码
COPY . .

# 数据目录（配合 docker-compose 挂载持久化）
RUN mkdir -p /app/data && chown -R app:app /app

ENV NODE_ENV=production \
    PORT=3000 \
    DATA_DIR=/app/data

USER app

EXPOSE 3000

# 健康检查：与应用内的 /healthz 路由配合
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/healthz >/dev/null 2>&1 || exit 1

CMD ["node", "server.js"]
