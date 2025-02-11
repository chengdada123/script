#!/bin/bash

# 定义全局版本号
VERSION_V1="v1.7.3"
VERSION_V0="v0.20.5"

# 定义操作系统和架构
OS=$(uname | tr '[:upper:]' '[:lower:]')  # 获取操作系统名称并转换为小写
ARCH=$(uname -m)  # 获取架构
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi
# 定义下载链接
URL_V1="https://github.com/nezhahq/agent/releases/download/${VERSION_V1}/nezha-agent_${OS}_${ARCH}.zip"
URL_V0="https://github.com/nezhahq/agent/releases/download/${VERSION_V0}/nezha-agent_${OS}_${ARCH}.zip"

# 定义颜色输出
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
skyblue="\e[1;36m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
skyblue() { echo -e "\e[1;36m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

# 安装哪吒监控V1的函数
install_nezha_v1() {
    TARGET_DIR="/opt/nezha/nezhav1"
    CONFIG_FILE="$TARGET_DIR/config.yml"
    SERVICE_FILE="/etc/systemd/system/nezhav1-agent.service"

    # 如果文件夹中已经有 nezha-agent 和 config.yml，则直接重启服务
    if [ -f "$TARGET_DIR/nezha-agent" ] && [ -f "$CONFIG_FILE" ]; then
        green "检测到 nezha-agent 和 config.yml 已存在，直接重启服务。"
        systemctl restart nezhav1-agent
        green "nezhav1-agent 服务已重启。"
        return
    fi

    echo "检测到的系统架构: $ARCH"
    
    echo "创建目标文件夹: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"
    
    # 根据架构选择下载文件
    green "正在下载 $ARCH 版本文件..."
    wget -O nezha-agent.zip "$URL_V1"  >/dev/null 2>&1

    # 提示下载完成
    green "文件下载完成: nezha-agent.zip"

    # 解压文件到目标文件夹
    green "正在解压文件到 $TARGET_DIR"
    apt install unzip -y >/dev/null 2>&1
    yum install unzip -y >/dev/null 2>&1
    unzip -o nezha-agent.zip -d "$TARGET_DIR" >/dev/null 2>&1

    # 提示用户输入
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
    green "生成配置文件: $CONFIG_FILE"

    cat <<EOL > "$CONFIG_FILE"
client_secret: $NZ_CLIENT_SECRET
debug: false
disable_auto_update: false
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
    green "配置文件已生成: $CONFIG_FILE"

    # 创建服务文件
    green "创建服务文件: $SERVICE_FILE"

    cat <<EOL > "$SERVICE_FILE"
[Unit]
Description=Nezhav1 Agent
After=network.target

[Service]
Type=simple
ExecStart=/opt/nezha/nezhav1/nezha-agent -c /opt/nezha/nezhav1/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # 重新加载 systemd 并启动服务
    green "重新加载 systemd 并启动 nezhav1-agent 服务"
    systemctl daemon-reload
    systemctl enable nezhav1-agent
    systemctl start nezhav1-agent
    rm -rf /opt/nezha/nezhav1/nezha-agent.zip
    # 提示完成
    green "nezhav1-agent 服务已创建并启动"
}

# 安装哪吒监控V0的函数
install_nezhav0() {
    TARGET_DIR="/opt/nezha/nezhav0"
    
        if [ -f "$TARGET_DIR/nezha-agent" ] ; then
        green "检测到 nezha-agent 已存在，直接重启服务。"
        systemctl restart nezhav0-agent
        green "nezhav0-agent 服务已重启。"
        return
    fi
    
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"

    # 根据架构选择下载文件
    green "正在下载 $ARCH 版本文件..."
    wget -O nezha-agent.zip "$URL_V0"  >/dev/null 2>&1

    green "解压缩 nezha-agent..."
    apt install unzip -y >/dev/null 2>&1
    yum install unzip -y >/dev/null 2>&1
    unzip -o -q nezha-agent.zip -d "$TARGET_DIR"  >/dev/null 2>&1

    # 提示用户输入
    read -r -p "请直接输入后台复制的命令: " USER_INPUT

    # 使用 awk 提取服务域名/IP、端口和密钥
    SERVER=$(echo "$USER_INPUT" | awk '{for(i=1;i<=NF;i++) if($i=="install_agent") print $(i+1)}')
    PORT=$(echo "$USER_INPUT" | awk '{for(i=1;i<=NF;i++) if($i=="install_agent") print $(i+2)}')
    KEY=$(echo "$USER_INPUT" | awk '{for(i=1;i<=NF;i++) if($i=="install_agent") print $(i+3)}')

    # 检查提取的参数是否为空
    if [[ -z "$SERVER" || -z "$PORT" || -z "$KEY" ]]; then
        echo "无法从输入中提取服务域名/IP、端口和密钥。请确保输入格式正确。"
        return
    fi

    # 创建服务
    cat <<EOF > /etc/systemd/system/nezhav0-agent.service
[Unit]
Description=Nezha Agent v0
After=network.target

[Service]
ExecStart=/opt/nezha/nezhav0/nezha-agent -s $SERVER:$PORT -p $KEY
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl start nezhav0-agent
    systemctl enable nezhav0-agent
    rm -rf /opt/nezha/nezhav0/nezha-agent.zip
    green "nezhav0-agent 服务已创建并启动"
}

function list_services() {
    purple "当前运行的哪吒监控服务:"

    systemctl list-units --type=service | grep -E 'nezha.*-agent.service' | awk '{print $1, $3}'
    green "当前安装的哪吒监控服务:"
    systemctl list-unit-files --type=service | grep -E 'nezha.*-agent.service' | awk '{print $1, $2}'
}

function uninstall_nezhav1() {
    red "正在停止 nezhav1-agent 服务..."
    systemctl stop nezhav1-agent

    red "正在删除 nezhav1-agent 服务..."
    systemctl disable nezhav1-agent
    rm -f /etc/systemd/system/nezhav1-agent.service

    red "正在删除 /opt/nezha/nezhav1 文件夹..."
    rm -rf /opt/nezha/nezhav1

    red "nezhav1-agent 卸载完成，还需要在面板后台手动删除该服务器。"
}

function uninstall_nezhav0() {
    red "正在停止 nezhav0-agent 服务..."
    systemctl stop nezhav0-agent

    red "正在删除 nezhav0-agent 服务..."
    systemctl disable nezhav0-agent
    rm -f /etc/systemd/system/nezhav0-agent.service

    red "正在删除 /opt/nezha/nezhav0 文件夹..."
    rm -rf /opt/nezha/nezhav0

    red "nezhav0-agent 卸载完成。"
}

function uninstall_original_nezha() {
    red "正在停止原版 nezha-agent 服务..."
    systemctl stop nezha-agent

    red "正在删除原版 nezha-agent 服务..."
    systemctl disable nezha-agent
    rm -f /etc/systemd/system/nezha-agent.service

    red "正在删除 /opt/nezha/agent 文件夹..."
    rm -rf /opt/nezha/agent

    red "原版 nezha-agent 卸载完成。"
}

# 菜单函数
show_menu() {
    yellow    "请选择操作:"
    green    "1) 安装哪吒监控V1"
    yellow   "2) 安装哪吒监控V0"
    red      "3) 卸载哪吒监控V1"
    red      "4) 卸载哪吒监控V0"
    red      "5) 卸载  原版监控"
    purple   "6) 列出  所有监控"
    green    "00) 退出"
}

# 主程序
while true; do
    show_menu
    read -p "输入选项: " option
    case $option in
        1)
            install_nezha_v1
            ;;
        2)
            install_nezhav0
            ;;
        3)
            uninstall_nezhav1
            ;;
        4)
            uninstall_nezhav0
            ;;
        5)
            uninstall_original_nezha
            ;;
        6)
            list_services            
            ;;
        00)
            echo "退出"
            exit 0
            ;;
        *)
            red "无效选项，请重新选择。"
            ;;
    esac
    green "操作完成，返回主菜单..."
done
