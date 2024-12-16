#!/bin/bash

# 设置语言
export LANG=zh_CN.UTF-8

# 日志记录函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查依赖项
check_dependencies() {
    for cmd in wget unzip curl awk; do
        if ! command -v $cmd &>/dev/null; then
            echo "$cmd 未安装，请安装后重试。"
            exit 1
        fi
    done
}

# 参数化配置
BASE_DIR=$(pwd)
FDIP_DIR="${BASE_DIR}/FDIP"
CFST_DIR="${BASE_DIR}/CloudflareST"
URL="https://spurl.api.030101.xyz/50mb"
SAVE_PATH="${FDIP_DIR}/txt.zip"
IPAPI_URL="https://ipapi.co"

# 创建所需目录
mkdir -p "${FDIP_DIR}" "${CFST_DIR}"

# 检查依赖
check_dependencies

# 1. 下载 txt.zip 文件
log "开始下载 txt.zip"
download_url="https://zip.baipiao.eu.org/"
if ! wget "${download_url}" -O "${SAVE_PATH}"; then
    log "下载失败，脚本终止。"
    exit 1
fi

# 2. 解压 txt.zip 文件到 FDIP 文件夹
log "解压 txt.zip"
unzip -o "${SAVE_PATH}" -d "${FDIP_DIR}"

# 3. 合并并去重指定的文件
log "合并和去重文件"
find "${FDIP_DIR}" -type f -name '*.txt' -exec cat {} + | awk '!seen[$0]++' > "${FDIP_DIR}/all.txt"

# 4. 读取 all.txt 并查询归属地，按国家保存 IP 地址
log "查询 IP 地址归属地并按国家保存"

# 定义国家代码数组
declare -A countries=( ["SG"]="sg.txt" ["HK"]="hk.txt" ["US"]="us.txt" ["JP"]="jp.txt" ["KR"]="kr.txt" )

# 清空之前的国家文件
for country_file in "${countries[@]}"; do
    > "${CFST_DIR}/${country_file}"
done

# 查询 IP 地址并保存到对应的文件
filter_ip() {
    local ip=$1
    local country_code
    country_code=$(curl -s "${IPAPI_URL}/${ip}/country/" | tr -d '[:space:]')
    if [ $? -ne 0 ]; then
        log "获取 IP 地址 ${ip} 的国家代码失败，跳过该 IP。"
        return
    fi
    if [[ -n "${countries[$country_code]}" ]]; then
        echo "$ip" >> "${CFST_DIR}/${countries[$country_code]}"
    fi
}

export -f filter_ip
cat "${FDIP_DIR}/all.txt" | parallel -j 4 filter_ip  # 使用并行处理

# 6. 下载 CloudflareST_linux_amd64.tar.gz 文件到 CloudflareST 文件夹
log "下载 CloudflareST"
if [ ! -f "${CFST_DIR}/CloudflareST" ]; then
    wget -O "${CFST_DIR}/CloudflareST_linux_amd64.tar.gz" https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/CloudflareST_linux_amd64.tar.gz
    tar -xzf "${CFST_DIR}/CloudflareST_linux_amd64.tar.gz" -C "${CFST_DIR}"
    chmod +x "${CFST_DIR}/CloudflareST"
else
    log "CloudflareST 文件已存在，跳过下载步骤。"
fi

# 7. 执行 CloudflareST 进行测速
log "运行 CloudflareSpeedTest"

# 定义国家代码数组
declare -a country_codes=("SG" "HK" "US" "JP" "KR")

# 遍历每个国家代码并进行测速
for country_code in "${country_codes[@]}"; do
    ip_file="${CFST_DIR}/${country_code,,}.txt"  # 转换为小写
    output_file="${CFST_DIR}/${country_code,,}.csv"  # 输出文件

    # 检查文件是否存在
    if [[ -f "$ip_file" ]]; then
        log "对 ${country_code} 进行测速，使用文件 ${ip_file}"
        "${CFST_DIR}/CloudflareST" -tp 443 -f "$ip_file" -n 500 -dn 5 -tl 250 -tll 10 -o "$output_file"
    else
        log "文件 ${ip_file} 不存在，跳过测速。"
    fi
done

log "脚本执行完成"
