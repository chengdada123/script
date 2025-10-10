#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail



cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh
echo "清理"
printf '6\n1\ny\n\' | bash ./vm.sh &
echo "创建debian虚拟机，完成后请按回车键"
printf '1\n8\nwinsrv2022\n\n\n\n200G\n10240\n8\n\n\n\n\n0\n' | bash ./vm.sh &


#read -p "按回车键继续执行后续命令..."  # 等你手动回车

#printf '3\n1\n' | bash ./vm.sh &


read -p "按回车键继续执行后续命令..."  # 等你手动回车

cd ~/vms
rm -rf *.qcow2 *.img
touch winsrv2022.img
echo "下载镜像"

wget -c --tries=0 --timeout=30 --waitretry=5 --retry-connrefused --show-progress \
     -O winsrv2022.qcow2  https://ip.nl8.eu/winsrv2022.qcow2 

echo "启动虚拟机"
printf '2\n1\n' | bash ./vm.sh &

echo "完成！监听端口3389，请使用内网穿透工具链接，密码请联系TG @chushuo_ge"

 
