#!/bin/bash

# 设置语言
export LANG=zh_CN.UTF-8

# 配置目录
BASE_DIR=$(pwd)
FDIP_DIR="${BASE_DIR}/FDIP"
CFST_DIR="${BASE_DIR}/CloudflareST"
URL="https://spurl.api.030101.xyz/50mb"
SAVE_PATH="${FDIP_DIR}/txt.zip"

# 创建所需目录
mkdir -p "${FDIP_DIR}"
mkdir -p "${CFST_DIR}"

# 1. 下载 txt.zip 文件
echo "============================开始下载txt.zip============================="
download_url="https://zip.baipiao.eu.org/"
wget "${download_url}" -O "${SAVE_PATH}"
if [ $? -ne 0 ]; then
    echo "下载失败，脚本终止。"
    exit 1
fi

# 2. 解压 txt.zip 文件到 FDIP 文件夹
echo "===============================解压txt.zip==============================="
unzip -o "${SAVE_PATH}" -d "${FDIP_DIR}"

# 3. 合并并去重指定的文件
echo "==============================合并和去重文件============================="
#cat "${FDIP_DIR}/45102-1-443.txt" "${FDIP_DIR}/31898-1-443.txt" | sort -u > "${FDIP_DIR}/all.txt"
awk '!seen[$0]++' "${FDIP_DIR}/45102-1-443.txt" "${FDIP_DIR}/31898-1-443.txt" > "${FDIP_DIR}/all.txt"

# 5. 删除 FDIP 文件夹中除了 all.txt 文件之外的所有文件
echo "============================清理不必要的文件============================="
find "${FDIP_DIR}" -type f ! -name 'all.txt' -delete

# 6. 下载 CloudflareST_linux_amd64.tar.gz 文件到 CloudflareST 文件夹
echo "=========================下载和解压CloudflareST=========================="
if [ ! -f "${CFST_DIR}/CloudflareST" ]; then
    echo "CloudflareST文件不存在，开始下载..."
    wget -O "${CFST_DIR}/CloudflareST_linux_amd64.tar.gz" https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/CloudflareST_linux_amd64.tar.gz
    tar -xzf "${CFST_DIR}/CloudflareST_linux_amd64.tar.gz" -C "${CFST_DIR}"
    chmod +x "${CFST_DIR}/CloudflareST"
else
    echo "CloudflareST文件已存在，跳过下载步骤。"
fi

# 7. 执行 CloudflareST 进行测速
echo "======================运行 CloudflareSpeedTest ========================="
"${CFST_DIR}/CloudflareST" -tp 443 -f "${FDIP_DIR}/all.txt" -n 500 -tl 250 -tll 10 -o "${CFST_DIR}/ip.csv" -url "$URL" -dd

echo "===============================脚本执行完成==============================="
