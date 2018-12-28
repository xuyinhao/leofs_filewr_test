#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
#echo "testdir $2"
testfile="java -jar ${cpath}/lib/FileTest.jar"
filesh=FileTest1.sh
threadnum=$threadnum1
ftelog=${testdir}/log/filetesterror.log
ftlog=${testdir}/log/ftlog1_${filesize1}_${recsize1}.log
ftpath=${testdir}/ft1_${filesize1}x${threadnum}_${recsize1}

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
valw=`$testfile ${ftpath} 1 $threadnum 1 ${filesize1} ${recsize1} 0 2>&1`
flag=$?
checkok $flag "write__$valw"

if [[ "$valw" =~ "Useage" ]]||[[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
	echo -e "$filesh:$numt ${filesize1}_${recsize1} write  failed "
        echo -e "$filesh:$numt write \n $valw" >> $ftelog
	#continue
else
	echo -e "$filesh:$numt ${filesize1}_${recsize1} wirte  pass  "
	echo -e "$filesh:$numt write \n $valw" >> $ftlog
 #       exit
fi
}
function check {
#read file
valr=`$testfile ${ftpath} 2 $threadnum 1 ${filesize1} ${recsize1} 0 2>&1 `
flag=$?
checkok $flag "read__$valr"

if [[ "$valr" =~ "Useage" || "$valr" =~ "error" ]]||[[ "$valr" =~ "Error" ]]||[ "$flag" != "0"  ];then
        echo -e "$filesh:$numt ${filesize1}_${recsize1} read  faild"
        echo -e "$filesh:$numt  read \n $valr" >> $ftelog
else
       echo -e "$filesh:$numt ${filesize1}_${recsize1} read  pass "
       echo -e "$filesh:$numt  read \n  $valr" >> $ftlog
fi
}
menu $1
#echo  "menu  $1"
