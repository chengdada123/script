#!/usr/bin/env bash

# .env 或直接 export
DATABRICKS_HOST="${DATABRICKS_HOST:-https://<your-databricks-host>}"
DATABRICKS_TOKEN="${DATABRICKS_TOKEN:-<your-pat-token>}"

if [[ -z "$DATABRICKS_HOST" || -z "$DATABRICKS_TOKEN" ]]; then
  echo "❌ 请先设置 DATABRICKS_HOST 和 DATABRICKS_TOKEN 环境变量"
  exit 1
fi

# 每页数量
PAGE_SIZE=50
PAGE_TOKEN=""

while :; do
  # 调用 API 列出 Apps
  RESPONSE=$(curl -s -X GET "$DATABRICKS_HOST/api/2.0/apps?page_size=$PAGE_SIZE&page_token=$PAGE_TOKEN" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    -H "Content-Type: application/json")

  # 提取 Apps 数组
  APPS=$(echo "$RESPONSE" | jq -c '.apps[]?')

  if [[ -z "$APPS" ]]; then
    echo "⚠️ 当前工作区没有找到任何 Apps"
    break
  fi

  # 遍历每个 App
  echo "$APPS" | while read -r APP; do
    NAME=$(echo "$APP" | jq -r '.name')
    COMPUTE_STATE=$(echo "$APP" | jq -r '.compute_status.state // "UNKNOWN"')
    echo "- $NAME | Compute状态: $COMPUTE_STATE"

    if [[ "$COMPUTE_STATE" != "ACTIVE" ]]; then
      echo "  ⚡ Compute未激活，正在启动 App '$NAME' ..."
      # 传入完整 App 对象启动
      curl -s -X POST "$DATABRICKS_HOST/api/2.0/apps/$NAME/start" \
        -H "Authorization: Bearer $DATABRICKS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$APP" | jq
      echo "  ✅ 启动请求已发送"
    else
      echo "  ✅ Compute 已激活，无需启动"
    fi
  done

  # 获取分页 token
  PAGE_TOKEN=$(echo "$RESPONSE" | jq -r '.next_page_token // empty')
  [[ -z "$PAGE_TOKEN" ]] && break
done
