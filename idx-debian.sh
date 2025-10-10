#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail



cd ~/vps
wget -O main.sh https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/main.sh
chmod +x main.sh
echo "清理"
printf '3\n6\n1\ny\n\0\n' | bash ./main.sh &

echo "创建debian虚拟机，完成后请按回车键"
printf '3\n1\n8\nwinsrv2022\ndebian\nroot\nvps888\n200G\n10240\n8\n\n\n\n\n2\n1\n' | bash ./main.sh &
read -p "按回车键继续执行后续命令..."  # 等你手动回车
echo "创建debian虚拟机成功，用户名：root 密码：vps888"
