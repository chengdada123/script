#!/usr/bin/env bash

# =============================
# Databricks CLI for Apps (带 startall)
# -list | -start <App> | -stop <App> | -delete <App> | -startall
# 支持传 App Name 或 ID
# 启动时轮询 compute_status 直到 ACTIVE
# =============================

DATABRICKS_HOST="${DATABRICKS_HOST:-https://<your-databricks-host>}"
DATABRICKS_TOKEN="${DATABRICKS_TOKEN:-<your-pat-token>}"

if [[ -z "$DATABRICKS_HOST" || -z "$DATABRICKS_TOKEN" ]]; then
  echo "❌ 请先设置 DATABRICKS_HOST 和 DATABRICKS_TOKEN 环境变量"
  exit 1
fi

# 调用 API
call_api() {
  local method=$1
  local url=$2
  local data=$3

  if [[ -n "$data" ]]; then
    curl -s -X "$method" "$DATABRICKS_HOST$url" \
      -H "Authorization: Bearer $DATABRICKS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$DATABRICKS_HOST$url" \
      -H "Authorization: Bearer $DATABRICKS_TOKEN" \
      -H "Content-Type: application/json"
  fi
}

# 获取 App 名称（支持 ID 或 Name）
resolve_appname() {
  local input=$1
  [[ -z "$input" ]] && echo "" && return
  call_api GET "/api/2.0/apps" | jq -r --arg id "$input" --arg name "$input" '.apps[] | select(.id==$id or .name==$name) | .name' | head -n1
}

# 获取 App 当前 compute 状态
get_compute_status() {
  local appname=$1
  call_api GET "/api/2.0/apps/$appname" | jq -r '.compute_status.state // "UNKNOWN"'
}

# 列出 Apps
list_apps() {
  local page_token=""
  local page_size=50
  while :; do
    RESPONSE=$(call_api GET "/api/2.0/apps?page_size=$page_size&page_token=$page_token")
    APPS=$(echo "$RESPONSE" | jq -c '.apps[]?')
    [[ -z "$APPS" ]] && { echo "⚠️ 当前工作区没有找到任何 Apps"; break; }

    echo "$APPS" | while read -r APP; do
      NAME=$(echo "$APP" | jq -r '.name')
      APPID=$(echo "$APP" | jq -r '.id // .name')
      COMPUTE=$(echo "$APP" | jq -r '.compute_status.state // "UNKNOWN"')
      STATUS=$(echo "$APP" | jq -r '.app_status.state // "UNKNOWN"')
      echo "- $NAME | ID: $APPID | App状态: $STATUS | Compute状态: $COMPUTE"
    done

    page_token=$(echo "$RESPONSE" | jq -r '.next_page_token // empty')
    [[ -z "$page_token" ]] && break
  done
}

# 启动 App 并轮询 compute_status
start_app() {
  local input=$1
  local appname=$(resolve_appname "$input")
  [[ -z "$appname" ]] && { echo "❌ 找不到 App: $input"; return; }

  local state=$(get_compute_status "$appname")
  if [[ "$state" == "ACTIVE" ]]; then
    echo "✅ App '$appname' 已经启动"
    return
  fi

  echo "⚡ 正在启动 App '$appname' ..."
  APP_OBJ=$(call_api GET "/api/2.0/apps/$appname")
  call_api POST "/api/2.0/apps/$appname/start" "$APP_OBJ" >/dev/null

  # 轮询 compute_status
  echo "⏳ 等待 compute 启动 ..."
  while :; do
    STATUS=$(call_api GET "/api/2.0/apps/$appname")
    STATE=$(echo "$STATUS" | jq -r '.compute_status.state // "UNKNOWN"')
    MESSAGE=$(echo "$STATUS" | jq -r '.compute_status.message // ""')

    echo -ne "  当前状态: $STATE - $MESSAGE\r"

    if [[ "$STATE" == "ACTIVE" ]]; then
      echo -e "\n✅ App '$appname' 启动成功！"
      break
    elif [[ "$STATE" == "ERROR" || "$STATE" == "FAILED" ]]; then
      echo -e "\n❌ App '$appname' 启动失败！"
      break
    fi
    sleep 5
  done
}

# 停止 App
stop_app() {
  local input=$1
  local appname=$(resolve_appname "$input")
  [[ -z "$appname" ]] && { echo "❌ 找不到 App: $input"; return; }

  local state=$(get_compute_status "$appname")
  if [[ "$state" == "INACTIVE" || "$state" == "STOPPED" ]]; then
    echo "✅ App '$appname' 已经停止 "
    return
  fi

  echo "⚡ 正在停止 App '$appname' ..."
  call_api POST "/api/2.0/apps/$appname/stop" '{}' >/dev/null
  echo "✅ 停止请求已发送"
}

# 删除 App
delete_app() {
  local input=$1
  local appname=$(resolve_appname "$input")
  [[ -z "$appname" ]] && { echo "❌ 找不到 App: $input"; return; }

  echo "⚡ 正在删除 App '$appname' ..."
  call_api DELETE "/api/2.0/apps/$appname" >/dev/null
  echo "✅ 删除请求已发送"
}

# 一键启动所有 compute_status 不是 ACTIVE 的 App
start_all_apps() {
  local page_token=""
  local page_size=50
  echo "⚡ 开始启动所有 compute_status 不是 ACTIVE 的 Apps ..."
  while :; do
    RESPONSE=$(call_api GET "/api/2.0/apps?page_size=$page_size&page_token=$page_token")
    APPS=$(echo "$RESPONSE" | jq -c '.apps[]?')
    [[ -z "$APPS" ]] && break

    echo "$APPS" | while read -r APP; do
      NAME=$(echo "$APP" | jq -r '.name')
      COMPUTE=$(echo "$APP" | jq -r '.compute_status.state // "UNKNOWN"')
      if [[ "$COMPUTE" != "ACTIVE" ]]; then
        start_app "$NAME"
      else
        echo "✅ App '$NAME' 已经是 ACTIVE，无需启动"
      fi
    done

    page_token=$(echo "$RESPONSE" | jq -r '.next_page_token // empty')
    [[ -z "$page_token" ]] && break
  done
  echo "✅ 所有可启动 App 已处理完成"
}

# =============================
# 命令行参数解析
# 默认不带参数执行 list
# =============================
if [[ $# -eq 0 ]]; then
  list_apps
  exit 0
fi

case $1 in
  -list)
    list_apps
    ;;
  -start)
    start_app "$2"
    ;;
  -stop)
    stop_app "$2"
    ;;
  -delete)
    delete_app "$2"
    ;;
  -startall)
    start_all_apps
    ;;
  *)
    echo "用法: $0 -list | -start <AppID或Name> | -stop <AppID或Name> | -delete <AppID或Name> | -startall"
    ;;
esac
