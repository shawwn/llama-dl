# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the GNU General Public License version 3.

#
# UPDATE from Shawn (Mar 5 @ 2:43 AM): Facebook disabled this URL. I've mirrored the files to an R2 bucket, which this script now points to.
#
#PRESIGNED_URL="https://dobf1k6cxlizq.cloudfront.net/*?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9kb2JmMWs2Y3hsaXpxLmNsb3VkZnJvbnQubmV0LyoiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE2NzgzNzA1MjR9fX1dfQ__&Signature=a387eZ16IkmbotdkEl8Z397Mvxhw4Bvk4SpEiDkqMLOMVMk5F962BzN5eKO-061g5vAEskn-CSrf4w3knubwPiFW69LTsJ8Amj-WOvtBOBy9soc43j77WGUU-3q2eNjMIyNZYsD~rub4EkUJGNpD61YtRrFvAU7tNQ1YMNL5-UUOk1~OHeaWerWisKPldufOyX6QdrrjeToVH1L0eGm1Ob4LnoYyLH96BHFou4XsOUR8NuyQfwYtmE2G6P2eKk~OV9-ABzYHxC2DyOWiWnt7WO~ELHnf17s9qreQAjEkCGEi4pHJ7BIkg6~ZfRmvRl3ZaPtqD80AH4SfO4hd5WQ0ng__&Key-Pair-Id=K231VYXPC1TA1R"             # replace with presigned url from email

PRESIGNED_URL="https://agi.gpt4.org/llama/LLaMA/*"

MODEL_SIZE="7B,13B,30B,65B"  # edit this list with the model sizes you wish to download
TARGET_FOLDER="./"             # where all files should end up

declare -A N_SHARD_DICT

N_SHARD_DICT["7B"]="0"
N_SHARD_DICT["13B"]="1"
N_SHARD_DICT["30B"]="3"
N_SHARD_DICT["65B"]="7"

echo "Downloading tokenizer"
wget ${PRESIGNED_URL/'*'/"tokenizer.model"} -O ${TARGET_FOLDER}"/tokenizer.model"
wget ${PRESIGNED_URL/'*'/"tokenizer_checklist.chk"} -O ${TARGET_FOLDER}"/tokenizer_checklist.chk"

(cd ${TARGET_FOLDER} && md5sum -c tokenizer_checklist.chk)

for i in ${MODEL_SIZE//,/ }
do
    echo "Downloading ${i}"
    mkdir -p ${TARGET_FOLDER}"/${i}"
    for s in $(seq -f "0%g" 0 ${N_SHARD_DICT[$i]})
    do
        wget ${PRESIGNED_URL/'*'/"${i}/consolidated.${s}.pth"} -O ${TARGET_FOLDER}"/${i}/consolidated.${s}.pth"
    done
    wget ${PRESIGNED_URL/'*'/"${i}/params.json"} -O ${TARGET_FOLDER}"/${i}/params.json"
    wget ${PRESIGNED_URL/'*'/"${i}/checklist.chk"} -O ${TARGET_FOLDER}"/${i}/checklist.chk"
    echo "Checking checksums"
    (cd ${TARGET_FOLDER}"/${i}" && md5sum -c checklist.chk)
done
