#!/bin/bash

# convert_lxc_template.sh

# 用法: ./convert_lxc_template.sh <源文件.tar.lzo> <目标文件.tar.xz>


set -e


if [ $# -ne 2 ]; then

    echo "Usage: $0 <源文件.tar.lzo> <目标文件.tar.xz>"

    exit 1

fi


SRC_FILE="$1"

TARGET_FILE="$2"


if [ ! -f "$SRC_FILE" ]; then

    echo "源文件不存在: $SRC_FILE"

    exit 1

fi


TMP_DIR=$(mktemp -d)

echo "[*] 创建临时目录 $TMP_DIR 并解压 $SRC_FILE ..."


# 解压 .tar.lzo

tar --lzo -xf "$SRC_FILE" -C "$TMP_DIR"


echo "[*] 打包为 zst 格式: $TARGET_FILE ..."

tar -I zstd -cf "$TARGET_FILE" -C "$TMP_DIR" .



echo "[*] 清理临时目录..."

rm -rf "$TMP_DIR"


echo "[*] 完成！生成文件: $TARGET_FILE"

