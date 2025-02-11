#!/bin/bash

cd ~/domains
mkdir -p nezhav1
cd nezhav1

if [ -f nezhav1 ]; then
    echo "nezhav1 已存在，跳过下载。"
else
    wget https://github.com/nezhahq/agent/releases/download/v1.7.3/nezha-agent_freebsd_amd64.zip >/dev/null 2>&1
    unzip nezha-agent_freebsd_amd64.zip >/dev/null 2>&1
    mv nezha-agent nezhav1
    chmod 755 nezhav1
fi

config_file="config.yml"

# 检查 config.yml 文件是否已存在
if [ -f "$config_file" ]; then
    echo "$config_file 已存在。"
else
    # 提示用户输入 client_secret 和 server
 read -p "请直接输入后台复制的命令: " USER_INPUT

    # 提取参数
    if [[ $USER_INPUT =~ NZ_SERVER=([^ ]+) ]]; then
        NZ_SERVER="${BASH_REMATCH[1]}"
    fi
    if [[ $USER_INPUT =~ NZ_TLS=([^ ]+) ]]; then
        NZ_TLS="${BASH_REMATCH[1]}"
    fi
    if [[ $USER_INPUT =~ NZ_CLIENT_SECRET=([^ ]+) ]]; then
        NZ_CLIENT_SECRET="${BASH_REMATCH[1]}"
    fi

    # 检查必需的环境变量是否存在
    if [ -z "$NZ_CLIENT_SECRET" ] || [ -z "$NZ_SERVER" ]; then
        echo "缺少必要的环境变量: NZ_CLIENT_SECRET 或 NZ_SERVER"
        return
    fi

    # 创建配置文件
 #   echo "生成配置文件: $config_file"

    cat <<EOL > "$config_file"
client_secret: $NZ_CLIENT_SECRET
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: false
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 1
server: $NZ_SERVER
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: $NZ_TLS
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: $(uuidgen)
EOL

    # 提示完成
#echo "配置文件已生成: $config_file"
fi
rm -rf nezha-agent_freebsd_amd64.zip
pkill nezhav1
sleep 2
chmod +x nezhav1
nohup ./nezhav1 -c config.yml >/dev/null 2>&1 &

echo "哪吒监控agent启动完成"
