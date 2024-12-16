import os
import glob
import requests
import zipfile
import time

# 定义目录
FDIP_DIR = 'your_directory_path'  # 替换为你的目录路径

# 1. 下载文件
def download_file(url, local_filename):
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    return local_filename

# 2. 解压文件
def extract_zip(zip_file, extract_to):
    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(extract_to)

# 3. 合并并去重指定的文件
def merge_and_deduplicate():
    print("==============================合并和去重文件=============================")

    # 查找 FDIP_DIR 目录下的所有 .txt 文件
    files_to_merge = glob.glob(os.path.join(FDIP_DIR, '*.txt'))
    unique_lines = set()

    # 读取每个文件并将行添加到集合中以去重
    for file in files_to_merge:
        with open(file, 'r', encoding='utf-8') as f:
            for line in f:
                unique_lines.add(line.strip())  # 使用 strip() 去掉行末尾的换行符

    # 将去重后的行写入 all.txt
    with open(os.path.join(FDIP_DIR, 'all.txt'), 'w', encoding='utf-8') as f:
        for line in sorted(unique_lines):  # 排序后写入
            f.write(line + '\n')


# 5. 测速（示例）
def speed_test():
    print("==============================测速=============================")
    start_time = time.time()
    # 这里可以放置测速代码，比如下载一个文件
    end_time = time.time()
    print(f"测速完成，耗时: {end_time - start_time:.2f} 秒")

# 主程序
if __name__ == "__main__":
    # 示例用法
    # download_file('http://example.com/file.zip', 'file.zip')
    # extract_zip('file.zip', FDIP_DIR)
    merge_and_deduplicate()
    clean_up_files()
    speed_test()
