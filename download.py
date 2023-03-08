import os
import sys
import hashlib
import requests
from tqdm import tqdm

PRESIGNED_URL = "https://agi.gpt4.org/llama/LLaMA/"
MODEL_SIZE = ["7B", "13B", "30B", "65B"]  # edit this list with the model sizes you wish to download
TARGET_FOLDER = "./"  # where all files should end up
N_SHARD_DICT = {"7B": 0, "13B": 1, "30B": 3, "65B": 7}


def md5sum(filename):
    try:
        fh = open(filename, 'rb')
    except IOError as e:
        print('Failed to open {} : {}'.format(filename, str(e)))
        return None

    md5 = hashlib.md5()
    try:
        while True:
            data = fh.read(65536)
            if not data:
                break
            md5.update(data)
    except IOError as e:
        fh.close()
        print('Failed to read {} : {}'.format(filename, str(e)))
        return None

    fh.close()
    return md5.hexdigest()


def checklist(folder, filename):
    try:
        fh = open(os.path.join(folder, filename), 'rb')
    except IOError as e:
        print('Failed to open {} : {}'.format(filename, str(e)))
        return

    n_failed = 0
    for line in fh:
        original_checksum, fn = line.split()
        original_checksum = original_checksum.decode('UTF-8')
        fn = os.path.join(folder, fn.decode('UTF-8'))
        checksum = md5sum(fn)
        if checksum is None:
            continue
        if checksum == original_checksum:
            print(fn + ": OK")
        else:
            print(fn + ": FAILED")
            n_failed += 1

    if n_failed > 0:
        print(f"WARNING: {n_failed} computed checksums did NOT match")
    fh.close()


def download(filename):
    r = requests.get(PRESIGNED_URL + filename, stream=True)
    with open(TARGET_FOLDER + filename, 'wb') as f:
        total_length = int(r.headers.get('content-length', 101))
        progress_bar = tqdm(total=total_length, unit='iB', unit_scale=True)
        for chunk in r.iter_content(chunk_size=1048576):
            if chunk:
                progress_bar.update(len(chunk))
                f.write(chunk)


print("Downloading tokenizer")
download("tokenizer.model")
download("tokenizer_checklist.chk")
checklist(TARGET_FOLDER, "tokenizer_checklist.chk")

for i in MODEL_SIZE:
    print(f"Downloading {i}")
    os.makedirs(f"{TARGET_FOLDER}/{i}", exist_ok=True)
    download(f"{i}/params.json")
    download(f"{i}/checklist.chk")

    for s in range(0, N_SHARD_DICT[i] + 1):
        download(f"{i}/consolidated.0{s}.pth")

    print("Checking checksums")
    checklist(TARGET_FOLDER + i, "checklist.chk")
