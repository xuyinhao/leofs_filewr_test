#!/bin/bash
#function to auto make file system and auto mount 
#author by zhangchao 2016-8-22
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
blkwrlog=${cpath}/log/blkwr.log
blkelog=${cpath}/log/blkerror.log
blksteplog2=${cpath}/log/blkstep.log
. ${cpath}/bin/common
. ${cpath}/bin/blkcommon

#mds=node100
DEVICE=$1   #device 
dst=$3
FILE_SYSTEM="ext4"    #file sys type

if [ $UID -ne 0 ];then
	blklog "must use root to exec the shell"
	exit
fi

#fdisk 
function FDISK(){
for t in $DEVICE
do
sleep 1
lsc=`ls /dev|grep leobd1d${t}p1`
fdiskc=`fdisk -l|grep "/dev/leobd1d${1}p1"`
sleep 0.1
if [ "$fdiskc" != "" ]||[ "$lsc" != "" ];then
	blklog  "leobd1d${t} has partion exist;skip fdisk"
else
	fdisk /dev/leobd1d$t >>/dev/null <<ESXU
n
p
1


w
ESXU
fi
files=`file -s /dev/leobd1d${t}p1`
if [[ "$files" =~ "data" ]];then
	blklog "check file -s /dev/leobd1d${t}p1 \033[32m pass\033[0m"
else
	blklog  "check file -s /dev/leobd1d${t}p1 \033[31m failed\033[0m"
	echo "$files" >> $blksteplog2
fi
done
wait
}
function DELFDISK(){

for t in  $DEVICE
do
#result2=`fdisk -l | grep "/dev/leobd1d${t}p1"`
result2=`ls /dev/ |grep "leobd1d${t}p1"`
if [ "$result2" = "" ];then
	blklog " /dev/leobd1d${t}p1 not exist ,pls check"
else
        fdisk /dev/leobd1d$t >> /dev/null <<ESXU
d
w
ESXU
 if [ "$files" = "" ];then
        blklog "check file -s /dev/leobd1d${t}p1 \033[32m pass\033[0m"
 else
        berrlog blklog "check file -s /dev/leobd1d${t}p1 \033[31m failed\033[0m"
 fi
fi
done
wait
}

function MKFS(){
for i in $DEVICE
	do
	sleep 1
		devmk="/dev/leobd1d${i}p1"
		result=`fdisk -l | grep "/dev/leobd1d${i}p1"` 
		ckdev=`file -s /dev/leobd1d${i}p1 |awk '{print $5}'`
		sleep 0.1
		if [ "$ckdev" = "${FILE_SYSTEM}" ];then
			blklog "exist $ckdev ,skip mkfs" # ext :$ckdev"
		elif [ -n "$result" ];then
			blklog  "\033[32m$devmk is exist,now start mkfs the $devmk\033[0m"
			#FILE_SYSTEM=ext4
			mkfs -t ${FILE_SYSTEM} ${devmk} 1>>/dev/null
		#	echo ${FILE_SYSTEM} ${devmk}
		else
			berrlog blklog "\033[31m$devmk is not exist,please check it first!\033[0m"
			berrlog blklog "fdiskresult:$result , file -s check:$ckdev"
			continue
		fi
	done
wait
}

function MOUNT(){
for j in $DEVICE
do
	mountdir=/mnt/blk/leobd1d${j}
	dfreturn1=`df|grep "/dev/leobd1d${j}p1"`
	if [ ! -d $mountdir ];then
			mkdir -p $mountdir
				if [ $? = 0 ];then
					blklog "mkdir $mountdir \033[32m success\033[0m"
				else
					berrlog blklog  "mkdir $mountdir \033[32m failed\033[0m"
					continue
				fi
		else
			:	
			#echo -e "\033[32mDirectory $mountdir is exist,needn't mkdir them again!\033[0m"
	fi
	
	dev2=`fdisk -l | grep "/dev/leobd1d${j}p1"`	
	if [ "$dfreturn1" != "" ];then
		berrlog blklog "/dev/leobd1d${j}p1 had beed mounted,mount \033[31mfailed\033[0m"
		
		echo -e "\033[31m/dev/leobd1d${j}p1 had beed mounted\033[0m" >> $blksteplog2
		continue
	elif [ -n "$dev2" ];then
		mount /dev/leobd1d${j}p1  $mountdir 
		flag=$?
		dfreturn=`df|grep "/dev/leobd1d${j}p1"`
		if [ $flag = 0 ]||[ "$dfreturn" != "" ];then
			blklog "mount /dev/leobd1d${j}p1 \033[32msuccess\033[0m"
		else 
			berrlog blklog "mount /dev/leobd1d${j}p1 \033[31m failed\033[0m"
			continue
		fi
	else
		berrlog blklog  "\033[31m/dev/leobd1d${j}p1 is not exist,please check!\033[0m"
		continue
	fi
done
wait
}

#big file, 60% of blkdev total size
function WFILE1 {
waitnum=1
bid="$DEVICE"
testwr $bid
echo "testwrite $DEVICE" >> $blkwrlog 
valw=`python ${cpath}/lib/wrfile.py /mnt/blk/leobd1d${bid}/bigf \
        1 $bigsize ${waitnum}k $bigfnum 1`
flag=$?
touch ${cpath}/conf/.tmp/tmparg${dst}
#sed -i s/leobd1d${bid}$/xxxx/g ${cpath}/conf/.tmp/tmparg  1>>$blkwrlog 2>>$blkelog
sleep 0.1
echo "$bigsize ${waitnum}k $bigfnum 1 leobd1d${bid}" >> ${cpath}/conf/.tmp/tmparg${dst}    # 1>> $blkwrlog 2>> $blkelog
if [[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
        berrlog blklog "leobd1d${bid} write \033[31m failed \033[0m"
	continue
else
        blklog "leobd1d${bid}  write \033[32m pass \033[0m "
        echo -e "leobd1d${bid}  write \n $valw" >> $blkwrlog

fi
}
function RFILE1 {
waitnum=1
bid=$DEVICE
#echo $bid
#echo $DEVICE
echo "testread $DEVICE" >> $blkwrlog
arg=`cat ${cpath}/conf/.tmp/tmparg${dst}|grep leobd1d${bid}$ |awk '{$(NF)="";print $0}'`
valr=`python ${cpath}/lib/wrfile.py /mnt/blk/leobd1d${bid}/bigf 2 $arg`
flag=$?
if [[ "$valr" =~ "error" ]]||[ "$flag" != "0" ];then
        berrlog "leobd1d${bid}  read \033[31m failed \033[0m" 
	echo -e "leobd1d${bid}  read \033[31m failed \033[0m"  >>  $blksteplog2
	continue
else
        blklog "leobd1d${bid} read \033[32m pass \033[0m "
        echo -e "leobd1d${bid} read \n $valr" >> $blkwrlog

fi
}

#small file ,
function WFILE2 {
waitnum=1
bid="$DEVICE"
testwr $bid
cyc=`expr $smallfnum / 100`
echo "testwrite $DEVICE" >> $blkwrlog
valw=`python ${cpath}/lib/wrfile.py /mnt/blk/leobd1d${bid}/smallf \
        1 $smallsize ${waitnum}k 100 $cyc`
flag=$?
touch ${cpath}/conf/.tmp/tmparg${dst}
#sed -i s/leobd1d${bid}$/xxxx/g ${cpath}/conf/.tmp/tmparg${dst} 1>>$blkwrlog 2>>$blkelog
sleep 0.1
echo "$smallsize ${waitnum}k 100 $cyc leobd1d${bid}" >> ${cpath}/conf/.tmp/tmparg${dst} # 1>>$blkwrlog 2>>$blkelog
if [[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
        berrlog blklog  "leobd1d${bid} write \033[31m failed \033[0m"
	continue
else
        blklog "leobd1d${bid}  write \033[32m pass \033[0m "
        echo -e "leobd1d${bid}  write \n $valw" >> $blkwrlog

fi
}
function RFILE2 {
waitnum=1
bid=$DEVICE
#echo $bid
#echo $DEVICE
echo "testread $DEVICE" >> $blkwrlog
arg=`cat ${cpath}/conf/.tmp/tmparg${dst}|grep leobd1d${bid}$ |awk '{$(NF)="";print $0}'`
valr=`python ${cpath}/lib/wrfile.py /mnt/blk/leobd1d${bid}/smallf 2 $arg`
flag=$?
if [[ "$valr" =~ "error" ]]||[ "$flag" != "0" ];then
        berrlog blklog "leobd1d${bid}  read \033[31m failed \033[0m"
	continue
else
        blklog "leobd1d${bid} read \033[32m pass \033[0m "
        echo -e "leobd1d${bid} read \n $valr" >> $blkwrlog

fi

}
 
#small file ，create.jar 8w个
function WFILE3 {
waitnum=1
bid="$DEVICE"
testwr $bid
echo "testwr $bid" >> $blkwrlog
#### dirnam num fname num fsize rszie threadnum depth flush
wargs="dir 20 file 10 $mulsize 10 20  3 0"
wargs2="dir 10 file 10 $mulsize 10 20 3 0"
#echo 3 > /proc/sys/vm/drop_caches
sleep 0.1
if [ "$sm" = "1" ];then
       wargs=${wargs2}
fi
valw=`java -jar ${cpath}/lib/create.jar  /mnt/blk/leobd1d${bid}/smf_mul $wargs 2>&1 &`
flag=$?
wait
touch ${cpath}/conf/.tmp/tmparg${dst}
#sed -i s/leobd1d${bid}$/xxxx/g ${cpath}/conf/.tmp/tmparg${dst}   1>>$blkwrlog 2>>$blkelog
sleep 0.1
echo "$wargs  leobd1d${bid}" >> ${cpath}/conf/.tmp/tmparg${dst} # 1>>$blkwrlog 2>>$blkelog
if [[ "$valw" =~ "error" ]]||[ "$flag" != "0" ]||[[ $valw  =~ "-jar" ]]||[[ $valw =~ "no basedir dir" ]];then
        berrlog blklog "leobd1d${bid} write \033[31m failed \033[0m"
	continue
else
        blklog "leobd1d${bid} write \033[32m pass \033[0m "
        echo -e "leobd1d${bid} write \n $valw" >> $blkwrlog

fi

}
function RFILE3 {
waitnum=1
bid=$DEVICE
#echo $bid
#echo $DEVICE
echo "testread $bid" >> $blkwrlog
arg=`cat ${cpath}/conf/.tmp/tmparg${dst}|grep leobd1d${bid}$ |awk '{$(NF)="";print $0}'`
#echo 3 > /proc/sys/vm/drop_caches
#sync
#sleep 2
valr=`java -jar ${cpath}/lib/check.jar  /mnt/blk/leobd1d${bid}/smf_mul $arg 2>&1 &`
flag=$?
wait
echo $valr >${cpath}/conf/.tmp/mulvar${bid}
mlog=${cpath}/conf/.tmp/mulvar${bid}
dataerr=`wordcount $mlog  dataerr`
noexist=`wordcount $mlog noexist`
lenerr=`wordcount $mlog  lenerr`

if [ "$dataerr" != "" -o  "$noexist" != "" -o "$lenerr" != "" ]||[ "$flag" != "0" ]||[[ $valr  =~ "-jar" ]]||[[ $valr =~ "no basedir dir" ]];then
       berrlog blklog "leobd1d${bid} dataerr:$dataerr noexist:$noexist lenerr:$lenerr  \033[31m faild\033[0m"
       echo -e "leobd1d${bid} $arg  check \n $valr" >> $blkelog
else
       blklog "leobd1d${bid} read \033[32m pass \033[0m"
       echo -e "leobd1d${bid}  $arg check  \n  $valr" >> $blkwrlog
   	rm -rf $mlog
fi
}

function RESIZE {
for d in ${DEVICE}
do
 rsizec=`ls /dev|grep leobd1d${d}p1`
 if [ "$rsizec" != "" ];then
   e2fsck -f -y /dev/leobd1d${d}p1  >>$blksteplog2 2>&1
 flag=$?
	if [ $flag != "0" ];then
		berrlog blklog "Maybe e2fsck  leobd1d${d}p1  has error "
		continue
	else
		blklog  "e2fsck  leobd1d${d}p1  \033[32mpass\033[0m"
	fi
 else
	berrlog blklog "  /dev/leobd1d${d}p1 not exist "
	continue
fi
 resize2fs /dev/leobd1d${d}p1  >>$blksteplog2 2>&1
if [ $? = "0" ];then
	blklog "resize2fs /dev/leobd1d${d}p1 \033[32mpass\033[0m"
else
	 berrlog blklog "resize2fs /dev/leobd1d${d}p1 \033[31mfailed\033[0m"
fi
done


}

function UMOUNT(){
for k in $DEVICE
do
	result2=`fdisk -l | grep "/dev/leobd1d${k}p1"`	
	if [ -n "$result2" ];then
		
		umount /dev/leobd1d${k}p1  & 2>$blksteplog2
		flag=$?
		sleep 1
		dfreturn=`df|grep "/dev/leobd1d${k}p1"`
		if [ $flag != 0 ]||[ "$dfreturn" != "" ];then
			umount /dev/leobd1d${k}p1  >/dev/null 2>&1 
			umount /dev/leobd1d${k}p1  >/dev/null 2>&1 
			berrlog blklog  "\033[31mumount /dev/leobd1d${k}p1 failed\033[0m"
			echo -e " dfreturn: $dfreturn ,flag =$flag" >> $blksteplog2
			continue
		else 
			blklog  "\033[32mumount /dev/leobd1d${k}p1 success\033[0m"
		fi
	else
		berrlog blklog "\033[31m/dev/leobd1d${k}p1 is not exist,please check![force umount it]\033[0m"
		umount /dev/leobd1d${k}p1 >> /dev/null 2>&1 &
		umount /dev/leobd1d${k}p1 >> /dev/null 2>&1 &
	fi
done
}

case $2 in
	fdisk)
		FDISK;;
	delfdisk)
		DELFDISK;;
	mkfs)
		MKFS;;
	mount)
		MOUNT;;
	umount)
		UMOUNT;;
	wfile1)
		WFILE1;;
	rfile1)
		RFILE1;;
	wfile2)
		WFILE2;;
	rfile2)
		RFILE2;;
	wfile3)
		WFILE3;;
	rfile3)
		RFILE3;;
	resizef)
		RESIZE;;		
	*)
		echo "Usage:$0  blkdevid fdisk|delfdisk|mkfs|mount|umount|resize "
		;;
esac
