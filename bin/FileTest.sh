#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
#echo "testdir $2"
testfile_jar="java -jar ${cpath}/lib/FileTest.jar"
filesh=$3
threadnum=$4
ftelog=$5
ftlog=$6
ftpath=$7
filesize=$8
recsize=$9

function init {
mkdir -p ${testdir}/log
rm -rf ${ftpath}
rm -rf $ftelog $ftlog
dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}
function run {
#write file
valw=`$testfile_jar ${ftpath} 1 $threadnum 1 ${filesize} ${recsize} 0 2>&1`
flag=$?
checkok $flag "write__$valw"

if [[ "$valw" =~ "Useage" ]]||[[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
	echo -e "$filesh:$numt ${filesize}_${recsize} write  failed "
        echo -e "$filesh:$numt write \n $valw" >> $ftelog
	#continue
else
	echo -e "$filesh:$numt ${filesize}_${recsize} wirte  pass  "
	echo -e "$filesh:$numt write \n $valw" >> $ftlog
 #       exit
fi
}
function check {
#read file
valr=`$testfile_jar ${ftpath} 2 $threadnum 1 ${filesize} ${recsize} 0 2>&1 `
flag=$?
checkok $flag "read__$valr"

if [[ "$valr" =~ "Useage" || "$valr" =~ "error" ]]||[[ "$valr" =~ "Error" ]]||[ "$flag" != "0"  ];then
        echo -e "$filesh:$numt ${filesize}_${recsize} read  faild"
        echo -e "$filesh:$numt  read \n $valr" >> $ftelog
else
       echo -e "$filesh:$numt ${filesize}_${recsize} read  pass "
       echo -e "$filesh:$numt  read \n  $valr" >> $ftlog
fi
#dmesg -c >> ${testdir}/log/FileTest1dmesg.log
}
menu $1
#echo  "menu  $1"
