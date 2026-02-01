#!/usr/bin/env bash
set -euo pipefail

# ========= 配置 =========
DB1="/opt/nezha/dashboard/data/sqlite.db"
DB2="/opt/nezha/dashboard_v0/data/sqlite.db"

TG_API="https://api.telegram.org/botXXXXXXX/sendMessage"
TG_CHAT_ID="XXXXXXX"

# ========= 函数 =========
bytes_to_human() {
    numfmt --to=iec --suffix=B "$1"
}

clean_if_exists() {
    local db="$1"
    local table="$2"
    local name="$3"

    if [[ ! -f "$db" ]]; then
        echo "⚠️ 跳过，不存在数据库: $db"
        return 0
    fi

    local size_before size_after freed
    size_before=$(stat -c %s "$db")

    sqlite3 "$db" <<EOF
DELETE FROM $table;
VACUUM;
EOF

    size_after=$(stat -c %s "$db")
    freed=$((size_before - size_after))

    local msg
    msg=$(cat <<EOF
🧹 $name 清理完成
📦 清理前：$(bytes_to_human "$size_before")
📉 清理后：$(bytes_to_human "$size_after")
♻️ 释放空间：$(bytes_to_human "$freed")
EOF
)

    echo "$msg"

    curl -s -X POST "$TG_API" \
        -F chat_id="$TG_CHAT_ID" \
        -F text="$msg" >/dev/null
}

# ========= 执行 =========
clean_if_exists "$DB1" "service_histories" "哪吒面板 NZ"
clean_if_exists "$DB2" "monitor_histories" "哪吒面板 Server Status"

echo "🎉 所有清理任务完成"
