#!/bin/bash

# 检查依赖
command -v jq >/dev/null 2>&1 || { echo "请安装 jq: apt install jq"; exit 1; }

INTERVAL=2

while true; do
    # 采集两次快照，并强制包装成 JSON 数组
    SNAP1=$(lxc list status=running --format json)
    sleep $INTERVAL
    SNAP2=$(lxc list status=running --format json)
    
    clear
    echo "LXD 实时监控 (按 CPU 排序前 10)"
    echo "系统: Debian 13  时间: $(date '+%H:%M:%S')  间隔: ${INTERVAL}s"
    echo "----------------------------------------------------------------------"
    printf "%-25s %-15s %-15s\n" "NAME" "CPU(%)" "MEM(MB)"
    echo "----------------------------------------------------------------------"

    # 将两个 JSON 组合成一个大数组 [data1, data2] 传给 jq
    echo "[$SNAP1, $SNAP2]" | jq -r --argjson interval "$INTERVAL" '
        (.[0]) as $old_list | (.[1]) as $new_list |
        $new_list[] | . as $new |
        ($old_list[] | select(.name == $new.name)) as $old |
        {
            name: $new.name,
            cpu: (($new.state.cpu.usage - $old.state.cpu.usage) / ($interval * 1000000000) * 100),
            mem: ($new.state.memory.usage / 1024 / 1024)
        } | "\(.name) \(.cpu) \(.mem)"
    ' | awk '{ printf "%-25s %-15.2f %-15.2f\n", $1, $2, $3 }' | sort -k2 -nr | head -n 10

    echo "----------------------------------------------------------------------"
    echo "按 [Ctrl+C] 退出"
done
