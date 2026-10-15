#!/usr/bin/env bash
# ============================================================
# 腾讯云 Lighthouse 轻量应用服务器 · 一次性初始化脚本
# 适用：Ubuntu 22.04 / 24.04 LTS（Debian 系可通用）
#
# 用法：
#   sudo bash init-lighthouse.sh
#
# 执行内容：
#   1. 系统更新与时区/时间同步
#   2. 创建日常运维用户 deployer
#   3. 安装 Docker 引擎并配置镜像加速 + 日志轮转
#   4. 创建 2G Swap（2G 内存机型必做）
#   5. 系统防火墙仅放行 22/80/443
#
# 注意：脚本可重复执行；执行前请确认已通过密钥登录成功。
# ============================================================
set -euo pipefail

OPER_USER="deployer"
SWAP_SIZE="2G"
DOCKER_MIRROR="https://mirror.ccs.tencentyun.com"   # 腾讯云内网镜像源

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 sudo 运行本脚本。" >&2
  exit 1
fi

# ---------- 1. 系统更新 / 时间 ----------
log "更新系统软件包……"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "设置时区为 Asia/Shanghai 并启用时间同步……"
timedatectl set-timezone Asia/Shanghai
apt-get install -y chrony
systemctl enable --now chrony
timedatectl | sed -n '1,6p'
ok "时间与系统更新完成"

# ---------- 2. 运维用户 ----------
if id "$OPER_USER" >/dev/null 2>&1; then
  warn "用户 $OPER_USER 已存在，跳过创建"
else
  log "创建运维用户 $OPER_USER ……"
  adduser --disabled-password --gecos "" "$OPER_USER"
  usermod -aG sudo "$OPER_USER"
  mkdir -p "/home/$OPER_USER/.ssh"
  if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "/home/$OPER_USER/.ssh/authorized_keys"
  fi
  chown -R "$OPER_USER:$OPER_USER" "/home/$OPER_USER/.ssh"
  chmod 700 "/home/$OPER_USER/.ssh"
  chmod 600 "/home/$OPER_USER/.ssh/authorized_keys" 2>/dev/null || true
  ok "用户 $OPER_USER 创建完成（免密 sudo，密钥已继承）"
fi

# ---------- 3. Docker ----------
if command -v docker >/dev/null 2>&1; then
  warn "Docker 已安装：$(docker --version)"
else
  log "安装 Docker 引擎……"
  curl -fsSL https://get.docker.com | sh
  ok "Docker 安装完成：$(docker --version)"
fi

systemctl enable --now docker

log "配置 Docker 镜像加速与日志轮转……"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["${DOCKER_MIRROR}"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
systemctl restart docker
usermod -aG docker "$OPER_USER" || true
ok "Docker 配置完成"

# ---------- 4. Swap ----------
if swapon --show | grep -q '/swapfile'; then
  warn "Swap 已启用，跳过"
else
  log "创建 ${SWAP_SIZE} Swap 文件……"
  fallocate -l "${SWAP_SIZE}" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  ok "Swap 创建完成"
fi
free -h

# ---------- 5. 防火墙 ----------
log "配置系统防火墙（仅放行 22/80/443）……"
apt-get install -y ufw
ufw allow 22/tcp   || true
ufw allow 80/tcp   || true
ufw allow 443/tcp  || true
ufw --force enable || true
ufw status verbose
ok "系统防火墙配置完成"

cat <<'TIP'

──────────────────────────────────────────────
 下一步（手动，别忘）：
   1) 在【腾讯云控制台 → 该实例 → 防火墙】中，
      放行 22 / 80 / 443 —— 云侧与系统侧是两套规则，都要配。
   2) 重新登录使 docker 用户组生效：
        ssh -i <私钥> deployer@<公网IP>
        docker ps
   3) 需要自建 PaaS 面板时：
        Coolify : curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
        Dokploy : curl -fsSL https://dokploy.com/install.sh | sudo sh
      面板端口请先用 SSH 隧道访问，别直接对公网开放。
──────────────────────────────────────────────
TIP

ok "初始化脚本执行完毕"
