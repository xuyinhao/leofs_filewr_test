#!/bin/sh
##########################################################################
#  DESCRIPTION  : filetest.jar temp  统一调用执行此文件
#  Para         : 
##########################################################################

cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common
. ${cpath}/lib/log_tool.sh
declare RET_LOG="$cpath"/log/ret.log
declare JOB_W_R=$1  							#属性：write , check ,all
declare -i s_value=$2							#属性，该脚本的第几个数据量的测试。必须为：正整数
declare TEST_TASK_INDEX=FileTest${s_value} #.sh	#测试任务，不同数据量的一个记录。FileTest数组 序号
declare testDir=$3

FileTestSize="${FileTest[$s_value]}"
fileSize=$(space_split "$FileTestSize" 1)
threadNum=$(space_split "$FileTestSize" 2)
recSize=$(space_split "$FileTestSize" 3)

declare testfile_jar="java -jar ${cpath}/lib/FileTest.jar"

declare ERROR_LOG_FILE_FULL_PATH="${testDir}/log/filetesterror.log"
declare ALL_LOG_FILE_FULL_PATH="${testDir}/log/ftlog${TEST_TASK_INDEX%.*}_${fileSize}_${recSize}.log"
declare testFilePath=${testDir}/${TEST_TASK_INDEX%.*}_${fileSize}x${threadNum}_${recSize}
init_log $ERROR_LOG_FILE_FULL_PATH
init_log $ALL_LOG_FILE_FULL_PATH

#sh ${cpath}/bin/FileTest.sh $1 $testdir $filesh $threadnum $ftelog $ftlog $ftpath $filesize $recsize
log_and_show "INFO" "$0,exce ${cpath}/bin/FileTest.sh $JOB_W_R $testDir $TEST_TASK_INDEX $threadNum $ERROR_LOG_FILE_FULL_PATH $ALL_LOG_FILE_FULL_PATH  $testFilePath $fileSize  $recSize"  "$LINENO" "$RET_LOG"
#ret=$(${cpath}/bin/FileTestMaster.sh "$JOB_W_R" "$testDir" "$TEST_TASK_INDEX" "$threadNum" "$ERROR_LOG_FILE_FULL_PATH" "$ALL_LOG_FILE_FULL_PATH"  "$testFilePath" "$fileSize"  "$recSize")
#echo $ret

function init {
mkdir -p ${testDir}/log >> /dev/null 2>&1
[ $? -ne 0 ] && log_error "${0},mkdir error" "$LINENO" "$RET_LOG" && return 1
rm -rf ${testFilePath}
rm -rf $ERROR_LOG_FILE_FULL_PATH  $ALL_LOG_FILE_FULL_PATH
dmesg -c > /dev/null
}

function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testDir}/log > /dev/null 2>&1
        rmdir ${testDir} > /dev/null 2>&1
#fi
}
ft_error_log()
{
local INFO_NAME="$1"
local LineNo="$2"
local WR_VALUE="$3"

 log_and_show "ERROR" "${0},${testFilePath}, $TEST_TASK_INDEX:$numt ${fileSize}x${threadNum}_${recSize} ${INFO_NAME}  failed" "$LineNo" "$RET_LOG"
    log_error "${0}, ${testFilePath},$TEST_TASK_INDEX:$numt ${INFO_NAME} \n $WR_VALUE" "$LineNo" "$ERROR_LOG_FILE_FULL_PATH"
    syslog "leofs_wr" "$0" 1 "${testFilePath},$TEST_TASK_INDEX:$numt ${INFO_NAME} failed"
}

ft_success_log()
{
local INFO_NAME="$1"
local LineNo="$2"
local WR_VALUE="$3"

 log_and_show "INFO" "${0},${testFilePath}, $TEST_TASK_INDEX:$numt ${fileSize}x${threadNum}_${recSize} ${INFO_NAME}  pass" "$LineNo" "$RET_LOG"
    log_info "${0}, ${testFilePath},$TEST_TASK_INDEX:$numt ${} \n $WR_VALUE" "$LineNo" "$ALL_LOG_FILE_FULL_PATH"
    syslog "leofs_wr" "$0" 0 "${testFilePath},$TEST_TASK_INDEX:$numt ${INFO_NAME} pass"
}


function run {
#write file
valw=`$testfile_jar ${testFilePath} 1 $threadNum 1 ${fileSize} ${recSize} 0 2>&1`
flag=$?
checkok $flag "write__$valw"

if [[ "$valw" =~ "Useage" ]]||[[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
    ft_error_log "ft_write" "$LINENO" "$valw"
	#continue
else
	ft_success_log "ft_write" "$LINENO"
 #       exit
fi
}

function check {
#read file
valr=`$testfile_jar ${testFilePath} 2 $threadNum 1 ${fileSize} ${recSize} 0 2>&1 `
flag=$?
checkok $flag "read__$valr"

if [[ "$valr" =~ "Useage" || "$valr" =~ "error" ]]||[[ "$valr" =~ "Error" ]]||[ "$flag" != "0"  ];then
	ft_error_log "ft_read" "$LINENO" "$valr"
else
	ft_success_log "ft_read" "$LINENO"
fi
#dmesg -c >> ${testDir}/log/FileTest1dmesg.log
}
menu "$JOB_W_R"

