#!/bin/bash
##$1=filename
tmpdir=/tmp
istorenum="2"
if [ "$1" == '' ];then
echo "xx.sh filename/dirname"
exit
fi
rm -f tmm
#if [ -d $1 ];then
getgrp="/LeoCluster/bin/leofs_getgrpinfo"
function getgrpinfo {
$getgrp $1 0 > $tmpdir/.filename$2
cat $tmpdir/.filename$2|grep "Devices" > $tmpdir/.Devices.info$2
dmm=`cat $tmpdir/.Devices.info${2}`
lines=`cat $tmpdir/.Devices.info${2}|wc -l`
for i in $(seq 1 $lines)
do
cat $tmpdir/.Devices.info$2|sed -n ${i}p > $tmpdir/.tmp1$2
for m in $(seq 1 $istorenum)
do
	wc=`cat  $tmpdir/.tmp1${2}|tr ' ' '\n'|grep "(${m})"|sort|wc -l`
	echo "$m" "$wc" >> tmm
done
done
}
#`cat Devices.info`
if [ -f $1 ];then

getgrpinfo $1
elif [ -d $1 ];then
dirls=`ls $1`
for i in $(ls $1)
do
getgrpinfo $1/$i $i &
done
fi
wait
sleep 0.2
errorflag=`cat error_getgrp*.log > /dev/null 2>&1`

if [ "$errorflag" = "" ];then
echo "check  $1 getgrp  pass"
else
echo "error"
fi
