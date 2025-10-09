#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail

DEST_DIR="/home/user/vms"
FINAL_QCOW2="$DEST_DIR/winsrv2022.qcow2"


cd ~/vps
wget -O main.sh https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/main.sh
chmod +x main.sh
printf '3\n1\n8\n\n\n\n\n200G\n10240\n8\n\n\n\n' | bash ./main.sh

wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh

printf '3\n2\n1\n' | bash ./main.sh &
sleep 20
printf '\n3\n6\n1\n' | bash ./main.sh

cd ~/vms
rm -rf *.qcow2
wget https://ip.nl8.eu/winsrv2022.qcow2

echo "配置 vm.sh..."

conf_file=$(ls *.conf 2>/dev/null)
if [ -n "$conf_file" ]; then
    sed -i 's|^IMG_URL=.*|IMG_URL="'"$FINAL_QCOW2"'"|' "$conf_file"
fi



printf '2\n1\n' | bash ./vm.sh
