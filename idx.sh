

#!/bin/bash
set -e  # 遇到错误立即退出

# 1. 下载 VHD 镜像
cd /tmp
wget -O Win10_22H2.vhd.gz https://www.xiecloud.cn/d/Share/DDSystem/Win10_22H2.vhd.gz

# 2. 解压
gunzip -f Win10_22H2.vhd.gz

# 3. 转换为 qcow2
qemu-img convert -f vpc -O qcow2 Win10_22H2.vhd winsrv2022.qcow2

# 4. 清理旧的 qcow2 文件
# mkdir -p /home/user/vms
rm -f /home/user/vms/*.qcow2

# 5. 复制新的 qcow2 文件
cp winsrv2022.qcow2 /home/user/vms/winsrv2022.qcow2

# 6. 扩容 qcow2 镜像
cd /home/user/vms
qemu-img resize winsrv2022.qcow2 100G

# 7. 下载 vm.sh 脚本
cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh

# 8. 修改配置文件的 IMG_URL（假设只有一个 .conf 文件）
conf_file=$(ls *.conf 2>/dev/null)
if [ -n "$conf_file" ]; then
    sed -i 's|^IMG_URL=.*|IMG_URL="/home/user/vms/winsrv2022.qcow2"|' "$conf_file"
fi

# 9. 运行 vm.sh 并自动输入 3、2、1
printf '3\n2\n1\n' | bash ./vm.sh &











