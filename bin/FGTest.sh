#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common
. ${cpath}/lib/log_tool.sh

testfile="python ${cpath}/lib/filewr.py"		# 使用的测试工具

declare RET_LOG="$cpath"/log/ret.log			#程序执行 记录 返回日志路径
declare JOB_W_R=$1                              #属性：write , check ,all
declare -i s_value=$2                           #属性，该脚本的第几个数据量的测试。必须为：正整数
declare TEST_TASK_INDEX=fgFileTest${s_value} 	#测试任务，不同数据量的一个记录。FileTest数组 序号
declare testdir=$3								#测试 大路径。 具体路径为下面的ftpath

# 获取 default.conf里面FGTest数组值并解读拆分
FGTestSize="${FGTest[$s_value]}"
filesize=$(space_split "$FGTestSize" 1)
threadnum=$(space_split "$FGTestSize" 2)
recsize=$(space_split "$FGTestSize" 3)
#prefix=$(space_split "$FGTestSize" 4)
declare prefix=0
log_debug "FGTestSize,$TEST_TASK_INDEX,t:$threadnum f:$filesize r:$recsize p:$prefix" "$LINENO" "$RET_LOG"

ftelog=${testdir}/log/fg${s_value}_filetest_error.log
ftlog=${testdir}/log/fglog${s_value}_${filesize}_${recsize}.log
ftpath=${testdir}/fg${s_value}_${filesize}x${threadnum}_${recsize}/fg${s_value}_p${prefix}
log_debug "fgtest log path, ftelog:$ftelog , ftlog:$ftlog ,ft_test_path:$ftpath" "$LINENO" "$RET_LOG"

function init {
mkdir -p ${testdir}/log
mkdir -p $(dirname $ftpath)
rm -rf ${ftpath}
rm -rf $ftelog $ftlog
[ $? -eq 0 ] && log_debug "$0 init finished" "$LINENO" "$RET_LOG"
#dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
	rm -rf ${ftpath}_*
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
[ $? -eq 0 ] && log_debug "$0 remove_dir finished" "$LINENO" "$RET_LOG"
#fi
}

fg_error_log()
{
local INFO_NAME="$1"
local LineNo="$2"
local WR_VALUE="$3"
 log_and_show "ERROR" "$ftpath,${TEST_TASK_INDEX}:$numt ${filesize}_${recsize} $INFO_NAME  failed " "$LineNo" "$RET_LOG"
        log_error "$ftpath,${TEST_TASK_INDEX}:$numt $INFO_NAME \n '${WR_VALUE}'" "$LineNo"  "$ftelog"
        #continue
        syslog "leofs_wr" "$0" 1  "$ftpath,${TEST_TASK_INDEX}:$numt $INFO_NAME failed"
}

fg_success_log()
{
local INFO_NAME="$1"
local LineNo="$2"
local WR_VALUE="$3"
 log_and_show "INFO" "$ftpath,$TEST_TASK_INDEX:$numt ${filesize}_${recsize} $INFO_NAME  pass " "$LineNo" "$RET_LOG"
        log_info "$ftpath,${TEST_TASK_INDEX}:$numt $INFO_NAME \n '${WR_VALUE}'" "$LineNo"  "$ftlog"
        syslog "leofs_wr" "$0" 0  "$ftpath,${TEST_TASK_INDEX}:$numt $INFO_NAME pass"
}
#write file , before
base_run()
{
	valw=`$testfile ${ftpath} 1  ${filesize} ${recsize} $threadnum 0 0 $(($prefix+1)) >&1`
	flag=$?
	checkok $flag "base_write__$valw"
	
	if [[ "$valw" =~ "Useage" ]]||[[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
		fg_error_log "base_run_write" "$LINENO"  "$valw"
		return 1
	else
		fg_success_log "base_run_write" "$LINENO" "$valw"
		return 0
	fi
}

#overwrite file 
function run {
#Usage:filename optype(1:write, 2:read) filesize blocksize thread_num bskip eskip [prefix]
base_run
[ $? -ne 0 ] && echo "fg base wr error ; exit" && exit 
log_debug "$0,cmd:$testfile ${ftpath} 1  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1" "$LINENO" "$RET_LOG"
valw=`$testfile ${ftpath} 1  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1`
flag=$?
checkok $flag "write__$valw" 

if [[ "$valw" =~ "Useage" ]]||[[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
		fg_error_log "write" "$LINENO"  "$valw"
else
		fg_success_log "write" "$LINENO" "$valw"
fi
}

#read file
function check {
log_debug "$0,cmd:$testfile ${ftpath} 2  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1" "$LINENO" "$RET_LOG"
valr=`$testfile ${ftpath} 2  ${filesize} ${recsize} $threadnum 0 0 $prefix >&1 ` 
flag=$?
checkok $flag "read__$valr"

if [[ "$valr" =~ "Useage" || "$valr" =~ "error" ]]||[[ "$valr" =~ "Error" ]]||[ "$flag" != "0"  ];then
		fg_error_log "read" "$LINENO"  "$valr"
else
		fg_success_log "read" "$LINENO" "$valr"
fi
}
menu "$JOB_W_R"
#echo  "menu  $1"
