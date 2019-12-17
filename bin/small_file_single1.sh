#!/bin/bash
cpath1=`dirname $0`
cpath=`cd "${cpath1}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common
. ${cpath}/lib/log_tool.sh

declare RET_LOG="$cpath"/log/ret.log
declare JOB_W_R=$1
declare -i s_value=$2                    		       	#属性，该脚本的第几个数据量的测试。必须为：正整数
declare TEST_TASK_INDEX=small_file_single${s_value} 	#.sh #测试任务，不同数据量的一个记录。数组 序号
testdir=$3
small_fs_recyle=$small_f_s_recyle						#default 默认100轮循环
writefile="python ${cpath}/lib/wrfile.py"

filesh=${TEST_TASK_INDEX}
smfselog=${testdir}/log/smallf_single_error.log
smfslog=${testdir}/log/smfslog${s_value}.log
writepath_name=${testdir}/smf_single${s_value}/smf_single${s_value}
writepath=$(dirname $writepath_name)
smsSize=${small_file_single[$s_value]}
fileNum=$(space_split "$smsSize" 1)
fileSize=$(space_split "$smsSize" 2)

#pwdp=`pwd`
function init {
mkdir -p ${testdir}/log
for i in $(seq 1 9)
do
rm -rf $writepath/smf_single${s_value}_${i}_*.txt > /dev/null 2>&1 & 
done
wait
rm -rf ${dirname $writepath}/sm_single${s_vale}*  	#删除目录
rm -rf $smfselog $smfslog #删除旧日志
mkdir -p ${dirname $writepath}
dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}


function run {
#cd $testdir
#Usage:filename optype(1:write, 2:read) filesize(k,m,g,t) blocksize(k,m,g,t) thread_num cycle
valw=`$writefile smf_single${s_value}  1 $filesize $filesize $small_fs_recyle  ${fileNum} 2>&1`
flag=$?
checkok $flag "write_$valw"

if [[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
	echo -e "$filesh:$numt  write  failed "
        echo -e "$filesh:$numt  write \n $valw" >> $smfselog
else 
	echo -e "$filesh:$numt write  pass "
        echo -e "$filesh:$numt write \n $valw" >> $smfslog

fi
}

function check {
cd $testdir
valr=`$writefile smf_single${s_value} 2 1000 100 100 ${fileNum_sd1} 2>&1`
flag=$?
checkok $flag "read_$valr"

if [[ "$valr" =~ "error" ]]||[ "$flag" != "0" ];then
        echo -e "$filesh:$numt  read  failed "
        echo -e "$filesh:$numt  read \n $valr" >> $smfselog
else
        echo -e "$filesh:$numt read  pass "
        echo -e "$filesh:$numt read \n $valr" >> $smfslog

fi
}
menu $1
#echo $pwdp
#cd $pwdp

