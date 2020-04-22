#!/bin/bash
#This script splits the device’s memory image file pulled from MTK device into
#separate files for each section. It requires name of the source image file as
#a parameter. Applicable for images taken from chips МТ6572-МТ6577 & МТ6582 by
#SP Flash Tool.

OUT_DIR="files"

if [ "$1" = "" ]
then
    echo "No input file name."
    exit
fi

imgfile=$1

if [ ! -f "$imgfile" ]
then
    echo "File $imgfile not found."
    exit
fi

imgsize=$(stat -c %s "$imgfile")
maxoffset=$((imgsize - 1))
echo "Imgsize $imgsize Maxoffset $maxoffset"
echo

if [ -d "$OUT_DIR" ]
then
    rm -r $OUT_DIR
fi

mkdir $OUT_DIR

#This should be adjusted according to device scatter file
params=(
"PRELOADER 0x800 0x1D2DC preloader.bin"   #need to cut off the first 2048 bytes from
                                            #bakcup file, to get downloadable version
                                            #stock preloader size is 0x1D2DC, but
                                            #section size is 0x1400000 in scatter file
"MBR 0x1400000 0x200 MBR"     #512 byte partition table, but 0x80000 in scatter file
"EBR1 0x1480000 0x200 EBR1"   #512 byte partition table, but 0x80000 in scatter file
"PRO_INFO 0x1500000 0x300000 pro_info"
"NVRAM 0x1800000 0x500000 nvram.bin"
"PROTECT_F 0x1D00000 0xA00000 protect_f"
"PROTECT_S 0x2700000 0xA00000 protect_s"
"SECCFG 0x3100000 0x20000 seccfg"
"UBOOT 0x3120000 0x60000 uboot.bin"
"BOOTIMG 0x3180000 0x600000 boot.img"
"RECOVERY 0x3780000 0x600000 recovery.img"
"SEC_RO 0x3D80000 0x600000 secro.img"
"MISC 0x4380000 0x80000 misc"
"LOGO 0x4400000 0x300000 logo.bin"
"EBR2 0x4700000 0x200 EBR2"   #512 byte partition table, but 0x80000 in scatter file
"EXPDB 0x4780000 0xA00000 expdb"
"ANDROID 0x5180000 0x38400000 system.img"
"CACHE 0x3D580000 0x7E00000 cache.img"
"USRDATA 0x45380000 0x3CE00000 userdata.img"
"FAT 0x82180000 0x14AEA0000 FAT")

for index in $(seq 0 $((${#params[@]} - 1)))
do
    partname=$(echo "${params[$index]}" | awk '{print $1}')
    offset=$(($(echo "${params[$index]}" | awk '{print $2}')))
    length=$(($(echo "${params[$index]}" | awk '{print $3}')))
    filename=$(echo "${params[$index]}" | awk '{print $4}')

    if [[ "$offset" -gt "$maxoffset" ]]
    then
        echo "Warning! $partname outside of image!"
        echo
        continue
    fi
    
    echo -n "Processing $partname: "
    #echo $offset $length $filename
    maxlength=$((imgsize - offset))
    #((length = length>maxlength?maxlength:length))
    #echo "Maxlength $maxlength Length $length"
    if [[ "$length" -gt "$maxlength" ]]
    then
        length=$maxlength
        echo "Warning! $partname cross the image boundary & will be truncated."
    else
        echo
    fi

    dd if=$imgfile of="./$OUT_DIR/$filename" skip=$offset count=$length iflag=skip_bytes,count_bytes
    echo

done

echo 'Done.'
exit

