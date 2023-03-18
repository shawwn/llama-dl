# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the GNU General Public License version 3.

#
# UPDATE from Shawn (Mar 5 @ 2:43 AM): Facebook disabled this URL. I've mirrored the files to an R2 bucket, which this script now points to.
#
#PRESIGNED_URL="https://dobf1k6cxlizq.cloudfront.net/*?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9kb2JmMWs2Y3hsaXpxLmNsb3VkZnJvbnQubmV0LyoiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE2NzgzNzA1MjR9fX1dfQ__&Signature=a387eZ16IkmbotdkEl8Z397Mvxhw4Bvk4SpEiDkqMLOMVMk5F962BzN5eKO-061g5vAEskn-CSrf4w3knubwPiFW69LTsJ8Amj-WOvtBOBy9soc43j77WGUU-3q2eNjMIyNZYsD~rub4EkUJGNpD61YtRrFvAU7tNQ1YMNL5-UUOk1~OHeaWerWisKPldufOyX6QdrrjeToVH1L0eGm1Ob4LnoYyLH96BHFou4XsOUR8NuyQfwYtmE2G6P2eKk~OV9-ABzYHxC2DyOWiWnt7WO~ELHnf17s9qreQAjEkCGEi4pHJ7BIkg6~ZfRmvRl3ZaPtqD80AH4SfO4hd5WQ0ng__&Key-Pair-Id=K231VYXPC1TA1R"             # replace with presigned url from email

$PRESIGNED_URL="https://agi.gpt4.org/llama/LLaMA/*"

$MODEL_SIZE="7B","13B","30B","65B"  # edit this list with the model sizes you wish to download
$TARGET_FOLDER="C:\Users\xavie\Downloads\llama models\" # where all files should end up

$N_SHARD_DICT = @{
    "7B"  =0;
    "13B" =1;
    "30B" =3;
    "65B" =7
}

function Verify-Checksum {
    foreach($checksum_File in $(Get-ChildItem  -Filter *.chk | Select -Property Name))
    {
        foreach($line in $(Get-Content $checksum_File.Name))
        {            
            $expected_Hash = $($line.Trim().Split(' ') | Where-Object { $_.Trim() -ne '' })[0]
            $file_Name = $($line.Trim().Split(' ') | Where-Object { $_.Trim() -ne '' })[1]
            $calculated_Hash = (Get-FileHash -Algorithm MD5 -Path $file_Name).Hash

            Write-Host "$file_Name : " -NoNewline
            if ($expected_Hash -eq $calculated_Hash) {
                Write-Host "File checksum OK"
            } else {
                Write-Host "File checksum FAILED" -BackgroundColor Red
            }
        }
    }   
}

echo "Downloading tokenizer"
Invoke-WebRequest -Uri $($PRESIGNED_URL.Replace("*","tokenizer.model")) -OutFile ${TARGET_FOLDER}"/tokenizer.model"
Invoke-WebRequest -Uri $($PRESIGNED_URL.Replace("*","tokenizer_checklist.chk")) -OutFile ${TARGET_FOLDER}"/tokenizer_checklist.chk"

cd ${TARGET_FOLDER} 
Verify-Checksum


foreach ($i in $MODEL_SIZE)
{
    echo "Downloading $i"
    mkdir -p $TARGET_FOLDER/$i
    foreach( $s in @(0..$N_SHARD_DICT[$i] | % { '{0:D2}' -f $_ })){        
        Invoke-WebRequest -Uri $($PRESIGNED_URL.Replace("*","$i/consolidated.$s.pth")) -OutFile $TARGET_FOLDER/$i/consolidated.$s.pth
    }
    
    Invoke-WebRequest -Uri $($PRESIGNED_URL.Replace("*","$i/params.json")) -OutFile $TARGET_FOLDER/$i/params.json
    Invoke-WebRequest -Uri $($PRESIGNED_URL.Replace("*","$i/checklist.chk")) -OutFile $TARGET_FOLDER/$i/checklist.chk
    
    echo "Checking checksums"

    cd $TARGET_FOLDER/$i 
    Verify-Checksum        
}
