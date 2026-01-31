#!/usr/bin/env bash
set -euo pipefail

# ========= 配置 =========
DB1="/opt/nezha/dashboard/data/sqlite.db"
DB2="/opt/nezha/dashboard_v0/data/sqlite.db"

TG_API="https://api.telegram.org/XXXXXXXXXX/sendMessage"
TG_CHAT_ID="XXXXXXXXXX"

# ========= 函数 =========
clean_if_exists() {
    local db="$1"
    local table="$2"
    local msg="$3"

    if [[ ! -f "$db" ]]; then
        echo "⚠️ 跳过，不存在数据库: $db"
        return 0
    fi

    sqlite3 "$db" <<EOF
DELETE FROM $table;
VACUUM;
EOF

    echo "✅ 已清空 $table ($db)"
    curl -s -X POST "$TG_API" \
        -F chat_id="$TG_CHAT_ID" \
        -F text="$msg" >/dev/null
}

# ========= 执行 =========
clean_if_exists "$DB1" "service_histories" \
"[service_histories] 哪吒面板清理完成 NZ"

clean_if_exists "$DB2" "monitor_histories" \
"[monitor_histories] 哪吒面板清理完成 Server Status"

echo "🎉 清理任务结束"
