#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

LOGFILE="port_forwarding.log"

NETWORK_INTERFACE="vmbr1"


log() {

    echo "[$(date)] $1" >> "$LOGFILE"

}


log "开始执行端口转发脚本"


# 获取所有运行中的KVM虚拟机的ID和名称

VM_INFO=$(/usr/sbin/qm list | awk '/running/{print $1, $2}')

log "获取到的KVM虚拟机信息: $VM_INFO"


# 获取所有运行中的LXC容器的ID和名称

CT_INFO=$(/usr/sbin/pct list | awk '/running/{print $1, $2}')

log "获取到的容器信息: $CT_INFO"


# 获取KVM虚拟机MAC地址的函数

get_vm_mac() {

  local vm_id=$1

  /usr/sbin/qm config "$vm_id" | grep -i "net0:" | awk -F ',' '{print $1}' | awk -F '=' '{print $2}'

}


# 获取LXC容器MAC地址的函数

get_ct_mac() {

  local ct_id=$1

  /usr/sbin/pct config "$ct_id" | grep -i "net0" | awk -F ',|=' '{for(i=1;i<=NF;i++) if ($i ~ /hwaddr/) print $(i+1)}'

}


# 获取IP地址的函数

get_ip() {

  local mac=$1

  sudo arp-scan --interface="$NETWORK_INTERFACE" --localnet | grep -i "$mac" | awk '{print $1}'

}


# 设置端口转发函数

setup_port_forwarding() {

  local host_port=$1

  local ip=$2

  local port=$3


  # 检查是否已存在转发规则

  if ! iptables -t nat -L PREROUTING -n | grep -q "$ip:$port"; then

    iptables -t nat -A PREROUTING -p tcp --dport "$host_port" -j DNAT --to-destination "$ip:$port"

    iptables -t nat -A POSTROUTING -p tcp -d "$ip" --dport "$port" -j MASQUERADE

    log "添加转发规则：宿主机端口 $host_port -> $ip:$port"

  else

    log "转发规则已存在：宿主机端口 $host_port -> $ip:$port"

  fi

}


# 处理KVM虚拟机

if [ -n "$VM_INFO" ]; then

  while read -r VM_ID VM_NAME; do

    log "处理KVM虚拟机ID: $VM_ID, 名称: $VM_NAME"

    

    if [ -z "$VM_ID" ]; then

      log "无法获取KVM虚拟机ID $VM_ID 的MAC地址"

      continue

    fi


    VM_MAC=$(get_vm_mac "$VM_ID")

    if [ -z "$VM_MAC" ]; then

      log "无法获取KVM虚拟机ID $VM_ID 的MAC地址"

      continue

    fi

    log "获取到的KVM虚拟机MAC地址: $VM_MAC"

    

    VM_IP=$(get_ip "$VM_MAC")

    if [ -z "$VM_IP" ]; then

      log "无法获取KVM虚拟机MAC $VM_MAC 的IP地址"

      continue

    fi

    log "获取到的KVM虚拟机IP地址: $VM_IP"

    

    if [[ $VM_IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then

      IP_SUFFIX=$(echo "$VM_IP" | awk -F '.' '{print $4}')

      

      # 设置22端口的转发规则

      setup_port_forwarding $((22000 + IP_SUFFIX)) "$VM_IP" 22


      # 设置80端口的转发规则

      setup_port_forwarding $((18000 + IP_SUFFIX)) "$VM_IP" 80


      # 设置30-40端口的转发规则

      for PORT in {30..40}; do

        setup_port_forwarding $((PORT * 1000 + IP_SUFFIX)) "$VM_IP" $((PORT * 1000 + IP_SUFFIX))

      done

    else

      log "无效的IP地址: $VM_IP"

    fi

  done <<< "$VM_INFO"

else

  log "没有运行中的KVM虚拟机"

fi


# 处理LXC容器

if [ -n "$CT_INFO" ]; then

  while read -r CT_ID CT_NAME; do

    log "处理容器ID: $CT_ID, 名称: $CT_NAME"

    

    if [ -z "$CT_ID" ]; then

      log "无法获取容器ID $CT_ID 的MAC地址"

      continue

    fi


    CT_MAC=$(get_ct_mac "$CT_ID")

    if [ -z "$CT_MAC" ]; then

      log "无法获取容器ID $CT_ID 的MAC地址"

      continue

    fi

    log "获取到的容器MAC地址: $CT_MAC"

    

    CT_IP=$(get_ip "$CT_MAC")

    if [ -z "$CT_IP" ]; then

      log "无法获取容器MAC $CT_MAC 的IP地址"

      continue

    fi

    log "获取到的容器IP地址: $CT_IP"

    

    if [[ $CT_IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then

      IP_SUFFIX=$(echo "$CT_IP" | awk -F '.' '{print $4}')

      

      # 设置22端口的转发规则

      setup_port_forwarding $((22000 + IP_SUFFIX)) "$CT_IP" 22


      # 设置80端口的转发规则

      setup_port_forwarding $((18000 + IP_SUFFIX)) "$CT_IP" 80


      # 设置30-40端口的转发规则

      for PORT in {30..40}; do

        setup_port_forwarding $((PORT * 1000 + IP_SUFFIX)) "$CT_IP" $((PORT * 1000 + IP_SUFFIX))

      done

    else

      log "无效的IP地址: $CT_IP"

    fi

  done <<< "$CT_INFO"

else

  log "没有运行中的LXC容器"

fi


# 保存iptables规则

/sbin/iptables-save > /etc/iptables/rules.v4


log "端口转发规则设置完成。"

