#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#F_num=1			#该FileTest?.sh 为第几个
#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
#echo "testdir $2"
#testfile="java -jar ${cpath}/lib/FileTest.jar"
filesh=FileTest1.sh        #当前脚本名，用于日志打印和记录
threadnum=$threadnum1   #F 的线程数
filesize=$filesize1 	  #F 的文件 大小
recsize=$recsize1	  #F 的文件块大小
ftelog=${testdir}/log/filetesterror.log  #FileTest 错误日志记录
ftlog=${testdir}/log/ftlog1_${filesize}_${recsize}.log #F 日志记录
ftpath=${testdir}/ft1_${filesize}x${threadnum}_${recsize} #F的测试目录
#filesh=$3  
#threadnum=$4
#ftelog=$5
#ftlog=$6
#ftpath=$7
#filesize=$8
#recsize=$9
#echo "1:$1  2 :$testdir  3 :$filesh  4:$threadnum  5:$ftelog 6:$ftlog 7:$ftpath 8:$filesize  9:$recsize " >> log_1
sh ${cpath}/bin/FileTest.sh $1 $testdir $filesh $threadnum $ftelog $ftlog $ftpath $filesize $recsize
#echo  "menu  $1"
