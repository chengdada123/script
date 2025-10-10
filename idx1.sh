#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail

DEST_DIR="/home/user/vms"
FINAL_QCOW2="$DEST_DIR/winsrv2022.qcow2"


cd ~/vps
wget -O main.sh https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/main.sh
chmod +x main.sh
printf '3\n1\n8\n\n\n\n\n200G\n10240\n8\n\n\n\n\n2\n1\n' | bash ./main.sh &


read -p "按回车键继续执行后续命令..."  # 等你手动回车

printf '3\n3\n1\n' | bash ./main.sh

conf_file=$(ls *.conf 2>/dev/null)
if [ -n "$conf_file" ]; then
    sed -i 's|^IMG_URL=.*|IMG_URL="'"$FINAL_QCOW2"'"|' "$conf_file"
fi
read -p "按回车键继续执行后续命令..."  # 等你手动回车
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh
cd ~/vms
rm -rf *.qcow2
wget https://ip.nl8.eu/winsrv2022.qcow2

echo "配置 vm.sh..."





printf '2\n1\n' | bash ./vm.sh &

 
