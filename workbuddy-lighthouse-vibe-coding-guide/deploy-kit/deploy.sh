#!/usr/bin/env bash
# ============================================================
# 一键更新部署脚本
# 放置路径：/opt/my-vibe-app/deploy.sh
# 用法：      bash deploy.sh
#
# 流程：拉取最新代码 -> 重建并启动容器 -> 健康检查 -> 报告结果
# 特点：健康检查带重试；失败时非零退出，便于 CI 与人工第一时间发现
# ============================================================
set -euo pipefail

APP_DIR="/opt/my-vibe-app"
BRANCH="${DEPLOY_BRANCH:-main}"
PORT="${APP_PORT:-3000}"
HEALTH_PATH="${HEALTH_PATH:-/healthz}"
MAX_TRIES=15
SLEEP_SEC=2

log() { printf '\033[1;34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
ok()  { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }

cd "$APP_DIR"

# ---------- 0. 记录当前版本，便于回滚 ----------
PREV_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
log "当前版本：${PREV_COMMIT}，即将更新到 origin/${BRANCH}"

# ---------- 1. 拉取代码 ----------
log "拉取最新代码……"
git fetch --all --prune
git reset --hard "origin/${BRANCH}"
NEW_COMMIT="$(git rev-parse --short HEAD)"
log "代码已更新：${PREV_COMMIT} -> ${NEW_COMMIT}"

# ---------- 2. 重建并启动 ----------
log "构建并启动容器……"
docker compose up -d --build

# ---------- 3. 健康检查（带重试） ----------
log "执行健康检查 http://127.0.0.1:${PORT}${HEALTH_PATH} ……"
for i in $(seq 1 "$MAX_TRIES"); do
  if curl -fsS --max-time 3 "http://127.0.0.1:${PORT}${HEALTH_PATH}" >/dev/null 2>&1; then
    ok "部署成功（版本 ${NEW_COMMIT}），服务已就绪"
    docker compose ps
    exit 0
  fi
  printf '  等待服务就绪 %s/%s …\n' "$i" "$MAX_TRIES"
  sleep "$SLEEP_SEC"
done

# ---------- 4. 失败处理 ----------
err "健康检查未通过，部署判定为失败"
echo "────── 最近日志 ──────" >&2
docker compose logs --tail=60 >&2 || true
cat <<EOF >&2

────── 建议操作 ──────
 1. 查看完整日志： docker compose logs -f --tail=200
 2. 检查监听端口： ss -lntp | grep ${PORT}
 3. 回滚到上一版本：
      git reset --hard ${PREV_COMMIT}
      docker compose up -d --build
EOF
exit 1
