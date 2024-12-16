import os
import subprocess
import requests
import zipfile
import glob

# 设置语言
os.environ['LANG'] = 'zh_CN.UTF-8'

# 配置目录
BASE_DIR = os.getcwd()
FDIP_DIR = os.path.join(BASE_DIR, 'FDIP')
CFST_DIR = os.path.join(BASE_DIR, 'CloudflareST')
URL = "https://spurl.api.030101.xyz/50mb"
SAVE_PATH = os.path.join(FDIP_DIR, 'txt.zip')

# 创建所需目录
os.makedirs(FDIP_DIR, exist_ok=True)
os.makedirs(CFST_DIR, exist_ok=True)

# 1. 下载 txt.zip 文件
print("============================开始下载txt.zip=============================")
download_url = "https://zip.baipiao.eu.org/"
response = requests.get(download_url)

if response.status_code != 200:
    print("下载失败，脚本终止。")
    exit(1)

with open(SAVE_PATH, 'wb') as f:
    f.write(response.content)

# 2. 解压 txt.zip 文件到 FDIP 文件夹
print("===============================解压txt.zip===============================")
with zipfile.ZipFile(SAVE_PATH, 'r') as zip_ref:
    zip_ref.extractall(FDIP_DIR)

# 3. 合并并去重指定的文件
print("==============================合并和去重文件=============================")
files_to_merge = glob.glob(os.path.join(FDIP_DIR, '*.txt'))
unique_lines = set()


for file in files_to_merge:
    with open(file, 'r', encoding='utf-8') as f:
        unique_lines.update(f.readlines())

with open(os.path.join(FDIP_DIR, 'all.txt'), 'w', encoding='utf-8') as f:
    f.writelines(sorted(unique_lines))

# 5. 删除 FDIP 文件夹中除了 all.txt 文件之外的所有文件
print("============================清理不必要的文件=============================")
for file in glob.glob(os.path.join(FDIP_DIR, '*')):
    if not file.endswith('all.txt'):
        os.remove(file)

# 6. 下载 CloudflareST_linux_amd64.tar.gz 文件到 CloudflareST 文件夹
print("=========================下载和解压CloudflareST==========================")
cloudflare_st_path = os.path.join(CFST_DIR, 'CloudflareST')
if not os.path.exists(cloudflare_st_path):
    print("CloudflareST文件不存在，开始下载...")
    response = requests.get("https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/CloudflareST_linux_amd64.tar.gz")
    tar_gz_path = os.path.join(CFST_DIR, 'CloudflareST_linux_amd64.tar.gz')
    
    with open(tar_gz_path, 'wb') as f:
        f.write(response.content)

    # 解压缩
    subprocess.run(['tar', '-xzf', tar_gz_path, '-C', CFST_DIR])
    os.chmod(cloudflare_st_path, 0o755)
else:
    print("CloudflareST文件已存在，跳过下载步骤。")

# 7. 执行 CloudflareST 进行测速
print("======================运行 CloudflareSpeedTest =========================")
subprocess.run([cloudflare_st_path, '-tp', '443', '-f', os.path.join(FDIP_DIR, 'all.txt'), '-n', '500', '-tl', '250', '-tll', '10', '-o', os.path.join(CFST_DIR, 'ip.csv'), '-url', URL, '-dd'])

print("===============================脚本执行完成===============================")
