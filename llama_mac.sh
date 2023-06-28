#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the GNU General Public License version 3.
#
# Updated the run on Mac by @lkwbr.

PRESIGNED_URL="https://agi.gpt4.org/llama/LLaMA/*"

MODEL_SIZES=("7B" "13B" "30B" "65B")  # edit this list with the model sizes you wish to download
N_SHARDS=("0" "1" "3" "7")            # Number of shards for each model size

TARGET_FOLDER="./"                    # where all files should end up

RETRY_MAX=3 # Maximum number of retries
SLEEP_TIME=5 # Time to sleep between retries in seconds

function strong_curl() {
    local url=$1
    local output=$2
    local retry_count=0

    while ((retry_count <= RETRY_MAX))
    do
        if curl -L -C - -# "$url" -o "$output"; then
            return 0
        else
            echo "curl failed, retrying in $SLEEP_TIME seconds..."
            sleep $SLEEP_TIME
            retry_count=$((retry_count+1))
        fi
    done

    echo "curl failed after $retry_count attempts, exiting..."
    exit 1
}

echo "Downloading tokenizer"
strong_curl ${PRESIGNED_URL/'*'/"tokenizer.model"} ${TARGET_FOLDER}"/tokenizer.model"
strong_curl ${PRESIGNED_URL/'*'/"tokenizer_checklist.chk"} ${TARGET_FOLDER}"/tokenizer_checklist.chk"

EXPECTED_MD5=$(cat ${TARGET_FOLDER}"/tokenizer_checklist.chk" | awk '{print $1}')
ACTUAL_MD5=$(md5 -q ${TARGET_FOLDER}"/tokenizer.model")

if [[ "$EXPECTED_MD5" != "$ACTUAL_MD5" ]]; then
  echo "md5 checksum failed for tokenizer.model. Expected: $EXPECTED_MD5, got: $ACTUAL_MD5"
  exit 1
fi

for index in ${!MODEL_SIZES[*]}
do
    i=${MODEL_SIZES[$index]}
    echo "Downloading ${i}"
    mkdir -p ${TARGET_FOLDER}"/${i}"
    for s in $(seq -f "0%g" 0 ${N_SHARDS[$index]})
    do
        echo "Downloading ${i}/consolidated.${s}.pth"
        if curl -I -s -o /dev/null -w '%{http_code}' ${PRESIGNED_URL/'*'/"${i}/consolidated.${s}.pth"} | grep -q "200"
        then
            strong_curl ${PRESIGNED_URL/'*'/"${i}/consolidated.${s}.pth"} ${TARGET_FOLDER}"/${i}/consolidated.${s}.pth"
        fi
    done
    strong_curl ${PRESIGNED_URL/'*'/"${i}/params.json"} ${TARGET_FOLDER}"/${i}/params.json"
    strong_curl ${PRESIGNED_URL/'*'/"${i}/checklist.chk"} ${TARGET_FOLDER}"/${i}/checklist.chk"
    echo "Checking checksums"

    while IFS= read -r line
    do
      FILE=$(echo $line | awk '{print $2}')
      EXPECTED_MD5=$(echo $line | awk '{print $1}')
      ACTUAL_MD5=$(md5 -q ${TARGET_FOLDER}"/${i}/${FILE}")

      if [[ "$EXPECTED_MD5" != "$ACTUAL_MD5" ]]; then
        echo "md5 checksum failed for $FILE. Expected: $EXPECTED_MD5, got: $ACTUAL_MD5"
        exit 1
      fi
    done < ${TARGET_FOLDER}"/${i}/checklist.chk"
done
