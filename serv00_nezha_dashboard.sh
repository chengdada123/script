#!/bin/bash

re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }
yellow "开始检测系统状态"
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | grep -c "tcp")
udp_ports=$(echo "$port_list" | grep -c "udp")
tcp_port=$(echo "$port_list" | awk '/tcp/ {print $1}')
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
devil binexec on >/dev/null 2>&1
green "打开允许运行自己的程序成功。"
red "第一次运行请输入yes重连ssh"
red "请输入（yes/no）"
read answer

# 判断用户输入
if [ "$answer" = "yes" ]; then
  # 查找 sshd 进程的 PID
  PID=$(ps aux | grep '[s]shd' | awk '{print $2}')

  # 判断是否找到进程
  if [ -n "$PID" ]; then
    red "即将终止 sshd 进程：$PID"
    kill -9 $PID
    red "sshd 进程已被强制终止。"
  else
    red "未找到 sshd 进程。"
  fi
else
  yellow "操作已取消，ssh 不会被重启。"
fi

 
if [[ $tcp_ports -lt 1 ]]; then
    # 没有找到任何 TCP 端口时，创建新端口
    red "没有找到任何TCP端口，正在创建新端口..."
    attempt=0
    max_attempts=10  # 最大尝试次数，防止死循环
    while [[ $attempt -lt $max_attempts ]]; do
        tcp_port=$(shuf -i 10000-65535 -n 1)  # 随机生成一个端口
        result=$(devil port add tcp $tcp_port 2>&1)
        if [[ $result == *"succesfully"* ]]; then
            green "已添加TCP端口: $tcp_port"
            break
        else
            red "端口 $tcp_port_n 不可用，尝试其他端口..."
        fi
        attempt=$((attempt + 1))
    done
    if [[ $attempt -ge $max_attempts ]]; then
        red "尝试 $max_attempts 次仍无法添加TCP端口，请检查系统配置。"
        exit 1
    fi

elif [[ $tcp_ports -eq 1 ]]; then
    # 如果只有一个 TCP 端口，直接选择
    tcp_port=$(echo "$port_list" | awk '/tcp/ {print $1}')
    green "找到一个TCP端口: $tcp_port"

elif [[ $tcp_ports -ge 2 ]]; then
    # 如果有多个 TCP 端口，默认选择第一个
    green "找到多个TCP端口，选择其中一个作为监听端口..."
    tcp_port=$(echo "$port_list" | awk '/tcp/ {print $1; exit}')
    green "选择的TCP端口: $tcp_port"
fi

get_ip() {
  IP_LIST=($(devil vhost list | awk '/^[0-9]+/ {print $1}'))
  API_URL="https://status.eooce.com/api"
  IP=""
  THIRD_IP=${IP_LIST[0]}
  RESPONSE=$(curl -s --max-time 2 "${API_URL}/${THIRD_IP}")
  if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
      IP=$THIRD_IP
  else
      FIRST_IP=${IP_LIST[0]}
      RESPONSE=$(curl -s --max-time 2 "${API_URL}/${FIRST_IP}")
      
      if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
          IP=$FIRST_IP
      else
          IP=${IP_LIST[1]}
      fi
  fi
  echo "$IP"
}
available_ip=$(get_ip)
green "将使用$available_ip申请证书"
green "面板将使用$tcp_port端口"

yellow "是否使用自己的域名？(yes/no)"
read -r use_custom_domain

# 根据用户输入设置域名
if [ "$use_custom_domain" = "yes" ] || [ "$use_custom_domain" = "y" ]; then
  while true; do
    yellow "请输入你的域名："
    read -r custom_domain

    # 检查用户输入是否为空
    if [ -n "$custom_domain" ]; then
      domain="$custom_domain"
      yellow "请将域名解析到$available_ip"
      break
    else
      yellow "未输入有效域名，请重新输入。"
    fi
  done
elif [ "$use_custom_domain" = "no" ] || [ "$use_custom_domain" = "n" ]; then
  domain="nezha.${USERNAME}.serv00.net"
else
  red "无效输入，默认使用 nezha.${USERNAME}.serv00.net"
  domain="nezha.${USERNAME}.serv00.net"
fi

devil www del $domain  >/dev/null 2>&1
red "初始化网站成功"
sleep 5 
yellow "正在创建网站..."
devil www add $domain proxy localhost $tcp_port  >/dev/null 2>&1
green "创建网站成功"

devil www options $domain sslonly on  >/dev/null 2>&1
#devil ssl www add $available_ip le le nezha.${USERNAME}.serv00.net 
green "强制HTTPS设置成功"
mkdir ~/dev >/dev/null 2>&1
cd ~/dev
build() {
  yellow "开始清理"
  rm -rf ~/dev/nezha
  sleep 5
  yellow "开始克隆项目"
  git clone https://github.com/nezhahq/nezha.git >/dev/null 2>&1
  cd nezha/cmd/dashboard
  yellow "克隆项目成功"
  wget https://github.com/nezhahq/admin-frontend/releases/download/v1.7.3/dist.zip >/dev/null 2>&1
  unzip dist.zip >/dev/null 2>&1
  rm -rf admin-dist
  mv dist admin-dist
  rm -rf dist.zip

  wget https://github.com/hamster1963/nezha-dash-v1/releases/download/v1.20.0/dist.zip >/dev/null 2>&1
  unzip dist.zip >/dev/null 2>&1
  rm -rf user-dist
  mv dist user-dist
  rm -rf dist.zip
  cd ~/dev/nezha/pkg/geoip

  curl -o 1.mmdb  https://vps8.de/country_asn.mmdb >/dev/null 2>&1
  mv 1.mmdb geoip.db
  cd ~/dev/nezha
  sed -i '' '/docs "github.com\/nezhahq\/nezha\/cmd\/dashboard\/docs"/d' cmd/dashboard/controller/controller.go

  sed -i '' 's/docs\.SwaggerInfo\.Version, *//g' cmd/dashboard/controller/controller.go
  go clean -modcache
  export GOPROXY=https://goproxy.io,direct
  
  go mod tidy -v >/dev/null 2>&1
  green "开始编译"
  CGO_ENABLED=1 go build cmd/dashboard/main.go >/dev/null 2>&1
  green "编译成功"
}
target_path="${HOME}/dev/nezha/main"
if [ -e "$target_path" ]; then
  red "文件已存在。是否需要重新编译？(yes/no)"
  
  # 等待用户输入
  read -r user_input
  case $user_input in
    yes|y|Y)
      build  # 调用编译函数
      ;;
    no|n|N)
      yellow "已取消重新编译。"
      ;;
    *)
      yellow "无效输入，已取消重新编译。"
      ;;
  esac
else
  yellow "可执行文件不存在，正在执行编译命令..."
  build  # 调用编译函数
fi

pkill main
green "进行下一步工作"
sleep 2
mkdir ~/nezha >/dev/null 2>&1
cp ~/dev/nezha/main ~/nezha/main
cd ~/nezha

nohup ./main >/dev/null 2>&1 &
sleep 10

sed -i '' "s/^listenport: [0-9]*/listenport: $tcp_port/" ~/nezha/data/config.yaml

sed -i '' "s|^installhost: .*|installhost: \"$USERNAME.serv00.net:$tcp_port\"|" ~/nezha/data/config.yaml
#sed -i '' "s/^realipheader: .*/realipheader: X-Real-IP/"  ~/nezha/data/config.yaml
sed -i '' "s/^sitename: .*/sitename: Server Status/"  ~/nezha/data/config.yaml
sed -i '' "s/^language: .*/language: zh_CN/"  ~/nezha/data/config.yaml
#green "Updated config.yml OK"
pkill main
sleep 2
nohup ./main >/dev/null 2>&1 &
green "你的哪吒面板地址是：https://"$domain"，后台初始用户名和密码是admin/admin"
red "请及时修改你的密码。"
max_attempts=5
attempt=1

# 申请证书的函数
apply_certificate() {
  devil ssl www add $available_ip le le $domain
#  devil ssl www add 207.180.248.6 le le lenezha.filzmsqie.serv00.net
}

# 初次申请证书
output=$(apply_certificate)
yellow "证书申请$output"
if echo "$output" | grep -qE "\[ok\]|SNI"; then
green "证书申请成功"
else
# 检查申请是否失败
while echo "$output" | grep -q "[Error]"; do
  if [ $attempt -lt $max_attempts ]; then
    
    read -p "是否重新申请证书？请输入 yes 或 no: " user_input

    if [ "$user_input" = "yes" ]; then
      attempt=$((attempt + 1))
      yellow "重新申请证书 (第 $attempt 次)..."
      output=$(apply_certificate)
      yellow $output
    else
      yellow "操作已取消。"
      break
    fi
  else
    yellow "最大重试次数已达到，申请失败。"
    break
  fi
done

red "如果证书签发失败请至serv00网站后台申请或者稍后重试。"
fi

green "哪吒面板安装完成:https://$domain"
