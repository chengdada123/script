#!/bin/bash
set -e  # 遇到错误立即退出
set -o pipefail

# ---------------------------
# 配置
# ---------------------------
VHD_URL="https://www.xiecloud.cn/d/Share/DDSystem/Win10_22H2.vhd.gz"
VHD_GZ="/tmp/Win10_22H2.vhd.gz"
VHD_RAW="/tmp/Win10_22H2.vhd"
QCOW2="/tmp/winsrv2022.qcow2"
DEST_DIR="/home/user/vms"
FINAL_QCOW2="$DEST_DIR/winsrv2022.qcow2"
EXPECTED_SHA256="DC0072BA6DD22DE2FFD1EDBEF05688A9502374D752B0FA6A29C02C8080B800D8"
QCOW2_SIZE="100G"

# ---------------------------
# 1. 下载
# ---------------------------
echo "[1/7] 下载 VHD..."
mkdir -p /tmp
wget -O "$VHD_GZ" "$VHD_URL"

# ---------------------------
# 2. 校验 SHA256
# ---------------------------
echo "[2/7] 校验 SHA256..."
DOWNLOAD_SHA256=$(sha256sum "$VHD_GZ" | awk '{print toupper($1)}')
if [ "$DOWNLOAD_SHA256" != "$EXPECTED_SHA256" ]; then
    echo "SHA256 校验失败！文件可能损坏"
    exit 1
fi
echo "SHA256 校验通过 ✅"

# ---------------------------
# 3. 解压
# ---------------------------
echo "[3/7] 解压 VHD..."
gunzip -f "$VHD_GZ"

# ---------------------------
# 4. 检查 VHD 是否有效
# ---------------------------
echo "[4/7] 验证 VHD 文件..."
if ! qemu-img info "$VHD_RAW" > /dev/null 2>&1; then
    echo "VHD 文件损坏或无法识别！"
    exit 1
fi
echo "VHD 文件有效 ✅"

# ---------------------------
# 5. 转换为 QCOW2
# ---------------------------
echo "[5/7] 转换为 QCOW2..."
qemu-img convert -f vpc -O qcow2 "$VHD_RAW" "$QCOW2"

# 检查转换结果
if ! qemu-img check "$QCOW2" > /dev/null 2>&1; then
    echo "QCOW2 文件损坏或转换失败！"
    exit 1
fi
echo "QCOW2 转换成功 ✅"

# ---------------------------
# 6. 移动到目标目录并扩容
# ---------------------------
echo "[6/7] 移动 QCOW2 并扩容..."
mkdir -p "$DEST_DIR"
rm -f "$DEST_DIR"/*.qcow2
cp "$QCOW2" "$FINAL_QCOW2"

qemu-img resize "$FINAL_QCOW2" "$QCOW2_SIZE"

# 再次检查
qemu-img check "$FINAL_QCOW2"
echo "QCOW2 文件扩容成功 ✅"

# ---------------------------
# 7. 下载 vm.sh 并修改配置
# ---------------------------
echo "[7/7] 配置 vm.sh..."

conf_file=$(ls *.conf 2>/dev/null)
if [ -n "$conf_file" ]; then
    sed -i 's|^IMG_URL=.*|IMG_URL="'"$FINAL_QCOW2"'"|' "$conf_file"
fi

cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh

cd ~/vps
wget -O vm.sh https://raw.githubusercontent.com/chengdada123/script/refs/heads/main/vm.sh
chmod +x vm.sh

# 背景运行，同时保证输入传递
(
  printf '2\n1\n' | bash ./vm.sh
) &

echo "🎉 所有步骤完成！虚拟机准备就绪。"
