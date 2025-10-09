#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail
cd ~/vms
rm -rf *.qcow2
wget https://ip.nl8.eu/winsrv2022.qcow2

echo "配置 vm.sh..."

conf_file=$(ls *.conf 2>/dev/null)
if [ -n "$conf_file" ]; then
    sed -i 's|^IMG_URL=.*|IMG_URL="'"$FINAL_QCOW2"'"|' "$conf_file"
fi

cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh

printf '2\n1\n' | bash ./vm.sh
