vols=`fdisk -l |grep "Disk /dev/leobd1d${1}"|awk '{print $5}'`
         blksize=`expr $vols / 1024 / 1024`

if [ $blksize -lt 2048 ];then
                smallfnum=10000
                sm=1
         fi
echo $sm
