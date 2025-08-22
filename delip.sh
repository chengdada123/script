#!/bin/bash


set -euo pipefail



LOGFILE="clean_port_forwarding.log"


log() { echo "[$(date '+%F %T')] $1" | tee -a "$LOGFILE"; }



log "开始清理端口转发规则..."



is_ip_online() {


    local ip=$1


    ping -c 2 -W 1 "$ip" >/dev/null 2>&1


}



delete_rule() {


    local host_port=$1 ip=$2 port=$3


    log "删除转发规则: 宿主机端口 $host_port -> $ip:$port"


    iptables -t nat -D PREROUTING -p tcp --dport "$host_port" -j DNAT --to-destination "$ip:$port" || log "删除PREROUTING失败"


    iptables -t nat -D POSTROUTING -p tcp -d "$ip" --dport "$port" -j MASQUERADE || log "删除POSTROUTING失败"


}



iptables -t nat -S PREROUTING | while read -r line; do


    if [[ "$line" =~ ^-A\ PREROUTING.*-p\ tcp.*--dport\ ([0-9]+).*--to-destination\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+) ]]; then


        host_port="${BASH_REMATCH[1]}"


        ip="${BASH_REMATCH[2]}"


        port="${BASH_REMATCH[3]}"



        if ! is_ip_online "$ip"; then


            delete_rule "$host_port" "$ip" "$port"


        else


            log "目标IP $ip 在线，保留规则: 宿主机端口 $host_port -> $ip:$port"


        fi


    fi


done



log "端口转发规则清理完成。"

