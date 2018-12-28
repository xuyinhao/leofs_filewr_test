#!/bin/bash
##$1=filename
tmpdir=/tmp/
if [ "$1" == '' ];then
echo "xx.sh filename/dirname"
exit
fi
#if [ -d $1 ];then
getgrp="/LeoCluster/bin/leofs_getgrpinfo"
function getgrpinfo 
{
$getgrp $1 0 > $tmpdir/.filename$2
#rm -f error_getgrp.log
cat $tmpdir/.filename$2|grep "Devices" > $tmpdir/.Devices.info$2
dmm=`cat $tmpdir/.Devices.info${2}`
lines=`cat $tmpdir/.Devices.info${2}|wc -l`
#echo $lines
for i in $(seq 1 $lines)
do
cat $tmpdir/.Devices.info$2|sed -n ${i}p > $tmpdir/.tmp1$2
wca=`cat $tmpdir/.tmp1$2|tr ' ' '\n'|sort|uniq -d`
if [ "$wca" != '' ];then
echo 'error'
echo "$1 $i" "$wca" 
echo "$1 $i" "$wca" >> error_getgrp${2}.log
fi
done
#echo $2
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
