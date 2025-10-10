#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail



cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh
read -p "之前是否安装过虚拟机？(y/n): " choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo "清理"
    printf '6\n1\ny\n\0\n' | bash ./vm.sh &
else





echo "创建debian虚拟机，完成后请按回车键"
printf '1\n8\nwinsrv2022\n\n\n\n200G\n10240\n8\n\n\n\n\n0\n' | bash ./vm.sh &





read -p "按回车键继续安装windows"  # 等你手动回车

cd ~/vms
rm -rf *.qcow2 *.img
touch winsrv2022.img


echo "========== Windows 镜像下载模块 =========="

# 使用子 shell 或函数，避免影响主脚本
download_win_image() {
    echo "请选择要下载的 Windows 镜像："
    echo "1) Windows 10"
    echo "2) Windows Server 2022"
    read -p "请输入数字 (1 或 2, 默认1): " choice

    case $choice in
        1|"")
            echo "下载 Windows 10 镜像..."
            wget -c --tries=0 --timeout=30 --waitretry=5 --retry-connrefused --show-progress \
                -O winsrv2022.qcow2 https://ip.nl8.eu/winsrv2022.qcow2 || echo "下载 Windows 10 失败，继续脚本..."
            ;;
        2)
            echo "下载 Windows Server 2022 镜像..."
            wget -c --tries=0 --timeout=30 --waitretry=5 --retry-connrefused --show-progress \
                -O winsrv2022.qcow2 https://ip.nl8.eu/vm-2022.qcow2 || echo "下载 Windows Server 2022 失败，继续脚本..."
            ;;
        *)
            echo "无效选项，跳过下载..."
            ;;
    esac
}

# 调用函数，不影响前后脚本
download_win_image

echo "========== 镜像下载模块结束 =========="


echo "启动windows虚拟机"
cd ~/vps

printf '2\n1\n' | bash ./vm.sh &

echo "完成！监听端口3389，请使用内网穿透工具链接，密码请联系TG @chushuo_ge"
fi

 
