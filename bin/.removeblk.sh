#!/bin/bash
if [ "$2" = "" ];then
	echo "Usage:$0 startdevid enddevid"
	exit
fi

for i in $(seq $1 $2)
do
leofs_cfgcmd unmap-client $i 1 2 3 4 5 6  7 8 9 10 

aa=`leofs_cfgcmd show-all-blkdev|grep "^$i "|awk '{print $6}'` 
sleep 0.1 
 leofs_cfgcmd delete-blkdev $i $aa 1 
done
