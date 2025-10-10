#!/usr/bin/env bash
set -euo pipefail

FRP_URL="https://github.com/fatedier/frp/releases/download/v0.65.0/frp_0.65.0_linux_amd64.tar.gz"
WORKDIR="$HOME/frp_0.65.0"
ARCHIVE="$WORKDIR/frp_0.65.0_linux_amd64.tar.gz"
FRPC_BIN="$WORKDIR/frpc"
FRPC_CONF="$WORKDIR/frpc.toml"
FRPC_LOG="$WORKDIR/frpc.log"

mkdir -p "$WORKDIR"

prompt() {
  local varname="$1"; shift
  local prompt_text="$1"; shift
  local default="$1"; shift
  local input
  read -p "$prompt_text [$default]: " input
  input="${input:-$default}"
  printf -v "$varname" '%s' "$input"
}

echo "=== frpc 一键安装脚本 (v0.65.0) ==="
echo "安装目录: $WORKDIR"
echo

# 下载
echo "[1/6] 下载 frp 包..."
wget -c --tries=0 --timeout=30 --waitretry=5 --retry-connrefused --show-progress -O "$ARCHIVE" "$FRP_URL"

# 解压
echo "[2/6] 解压..."
tar -xzf "$ARCHIVE" -C "$WORKDIR" --strip-components=1

# 清理
echo "[3/6] 清理无用文件..."
shopt -s nullglob
rm -f "$WORKDIR"/*.service "$WORKDIR"/README* "$WORKDIR"/LICENSE* "$WORKDIR"/.github* || true
shopt -u nullglob

# 配置
echo "[4/6] 生成 frpc.toml"
prompt SERVER_ADDR "请输入 frps 服务器地址 (serverAddr)" "1.1.1.1"
prompt SERVER_PORT "请输入 frps 服务器端口 (serverPort)" "7000"
prompt AUTH_TOKEN "请输入 auth.token" "123456789"

# 备份旧配置
[ -f "$FRPC_CONF" ] && cp -a "$FRPC_CONF" "$FRPC_CONF.bak.$(date +%s)"

cat > "$FRPC_CONF" <<EOF
serverAddr = "$SERVER_ADDR"
serverPort = $SERVER_PORT
auth.method = "token"
auth.token = "$AUTH_TOKEN"
EOF

echo "现在开始添加映射，输入空名称结束添加"

while true; do
  read -p "映射名称 (name) (回车结束添加): " PROXY_NAME
  PROXY_NAME="${PROXY_NAME:-}"
  if [ -z "$PROXY_NAME" ]; then
    break
  fi

  while true; do
    read -p "类型 type (tcp/http) [tcp]: " PROXY_TYPE
    PROXY_TYPE="${PROXY_TYPE:-tcp}"
    if [[ "$PROXY_TYPE" == "tcp" || "$PROXY_TYPE" == "http" ]]; then
      break
    else
      echo "只支持 tcp 或 http"
    fi
  done

  # local_port
  while true; do
    read -p "本地端口 localPort (例如 3389): " LOCAL_PORT
    if [[ "$LOCAL_PORT" =~ ^[0-9]+$ ]]; then break; fi
    echo "请输入有效端口号"
  done

  if [ "$PROXY_TYPE" == "tcp" ]; then
    while true; do
      read -p "远端端口 remotePort (例如 33897): " REMOTE_PORT
      if [[ "$REMOTE_PORT" =~ ^[0-9]+$ ]]; then break; fi
      echo "请输入有效端口号"
    done

    cat >> "$FRPC_CONF" <<EOF

[[proxies]]
name = "$PROXY_NAME"
type = "tcp"
localIP = "127.0.0.1"
localPort = $LOCAL_PORT
remotePort = $REMOTE_PORT
EOF

  else
    read -p "custom_domains (逗号分隔，例如 example.com): " CUSTOM_DOMAINS
    CUSTOM_DOMAINS="$(echo "$CUSTOM_DOMAINS" | sed 's/ *, */,/g' | sed 's/^,//;s/,$//')"

    cat >> "$FRPC_CONF" <<EOF

[[proxies]]
name = "$PROXY_NAME"
type = "http"
localIP = "127.0.0.1"
localPort = $LOCAL_PORT
custom_domains = ["$CUSTOM_DOMAINS"]
EOF
  fi

  echo "已添加映射: $PROXY_NAME ($PROXY_TYPE)"
done

# 授权 frpc 可执行
chmod +x "$FRPC_BIN"

# 启动 frpc
echo "[5/6] 启动 frpc，日志输出到 $FRPC_LOG"
cd "$WORKDIR"
nohup "$FRPC_BIN" -c "$FRPC_CONF" >> "$FRPC_LOG" 2>&1 &

FRPC_PID=$!
sleep 1

if ps -p "$FRPC_PID" >/dev/null 2>&1; then
  echo "frpc 已启动，PID=$FRPC_PID"
  echo "日志文件: $FRPC_LOG"
else
  echo "frpc 启动失败，请查看日志 $FRPC_LOG"
fi

echo "完成，编辑 $FRPC_CONF 可修改配置。"
