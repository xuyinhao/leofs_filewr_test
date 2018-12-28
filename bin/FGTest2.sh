#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
#echo "testdir $2"
testfile="python ${cpath}/lib/filewr.py"
filesh=FGTest2.sh
threadnum=$fgthreadnum2
filesize=$fgfilesize2
recsize=$fgrecsize2
prefix=$fgprefix2

ftelog=${testdir}/log/fgfiletesterror.log
ftlog=${testdir}/log/fglog1_${filesize}_${recsize}.log
ftpath=${testdir}/fg1_${filesize}x${threadnum}_${recsize}

function init {
mkdir -p ${testdir}/log
rm -rf ${ftpath}
rm -rf $ftelog $ftlog
#dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
	rm -rf ${ftpath}
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}
function run {
#write file
#Usage:filename optype(1:write, 2:read) filesize blocksize thread_num bskip eskip [prefix]
valw=`$testfile ${ftpath} 1  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1`
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
valr=`$testfile ${ftpath} 2  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1 `
flag=$?
checkok $flag "read__$valr"

if [[ "$valr" =~ "Useage" || "$valr" =~ "error" ]]||[[ "$valr" =~ "Error" ]]||[ "$flag" != "0"  ];then
        echo -e "$filesh:$numt ${filesize}_${recsize} read  faild"
        echo -e "$filesh:$numt  read \n $valr" >> $ftelog
else
       echo -e "$filesh:$numt ${filesize}_${recsize} read  pass "
       echo -e "$filesh:$numt  read \n  $valr" >> $ftlog
fi
}
menu $1
#echo  "menu  $1"
