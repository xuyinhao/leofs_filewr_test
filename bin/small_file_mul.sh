#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd ..;pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common
. ${cpath}/lib/log_tool.sh

declare RET_LOG="$cpath"/log/ret.log
declare JOB_W_R=$1 
declare -i s_value=$2                           #属性，该脚本的第几个数据量的测试。必须为：正整数
declare TEST_TASK_INDEX=small_file_mul${s_value} #.sh #测试任务，不同数据量的一个记录。数组 序号
testdir=$3
createcmd="java -jar ${cpath}/lib/create.jar"
checkcmd="java -jar ${cpath}/lib/check.jar"
filesh=$TEST_TASK_INDEX
smfmelog=${testdir}/log/${TEST_TASK_INDEX}_error.log
smfmlog=${testdir}/log/${TEST_TASK_INDEX}.log
declare declare testFilePath="$testdir/$TEST_TASK_INDEX"

smallFileMulSize=${small_file_mul[$s_value]}
dirNum=$(space_split "$smallFileMulSize" 1)
fileNum=$(space_split "$smallFileMulSize" 2)
depth=$(space_split "$smallFileMulSize" 3)

function init {
	mkdir -p ${testdir}/log
	for i in $(seq 0 $((10#$dirNum-1)))
	do
   		rm -rf ${testFilePath}/dir$i &
	done
	wait
	rm -rf ${testFilePath}
	rm -rf $smfmelog $smfmlog
	dmesg -c > /dev/null
}
function remove_dir {
	#if [ "$cmdcmd" = "remove" ];then
	rmdir ${testdir}/log > /dev/null 2>&1
	rmdir ${testdir} > /dev/null 2>&1
	#fi
}

smfm_success_log()
{
	local INFO_NAME="$1"
	local LineNo="$2"
	local WR_VALUE="$3"

	log_and_show "INFO" "$filesh:$numt :dir:$dirNum file:$fileNum depth:$depth  ${INFO_NAME}  pass " "$LineNo" "$RET_LOG"
	log_info "${testFilePath}, $filesh:$numt ${INFO_NAME} \n '${WR_VALUE}'" "$LineNo" "$smfmlog"
    syslog "leofs_wr" "$0" 0 "${testFilePath},$filesh:$numt ${INFO_NAME} pass"
}

smfm_error_log()
{
	local INFO_NAME="$1"
	local LineNo="$2"
	local WR_VALUE="$3"

    log_and_show "ERROR" "$filesh:$numt dir:$dirNum file:$fileNum depth:$depth  ${INFO_NAME} failed " "${LineNo}" "$RET_LOG"
    log_error  "${testFilePath} $filesh:$numt  ${INFO_NAME} \n '${WR_VALUE}'" "$LineNo" "$smfmelog"
    syslog "leofs_wr" "$0" 1 "${testFilePath} $filesh:$numt  ${INFO_NAME} failed"
}

function run {
	#create file
	log_debug "$0,small_file_mul_write_cmd: $createcmd $testFilePath dir $dirNum file $fileNum 0 0 30 $depth 0 2>&1"
	valw=`$createcmd $testFilePath dir $dirNum file $fileNum 0 0 30 $depth 0 2>&1` 
	checkok $? "create__$valw"
	if [[ "$valw" =~ "speed:" ]];then
		smfm_success_log "small_file_mul create" "$LINENO" "$valw"
	else 
		smfm_error_log "small_file_mul create" "$LINENO" "$valw"
	fi
}

#check file
function check {
	log_debug "$0,small_file_mul_check_cmd:$checkcmd ${testFilePath} dir $dirNum file $fileNum 0 0 30 $depth 0 2>&1"
	valr=`$checkcmd ${testFilePath} dir $dirNum file $fileNum 0 0 30 $depth 0 2>&1`
	checkok $? "check__$valr"
	#echo $valr >> $smfmlog
	dataerr=`wordcount $smfmlog  dataerr`
	noexist=`wordcount $smfmlog noexist`
	lenerr=`wordcount $smfmlog  lenerr`
	if [ "$dataerr" != "" -o  "$noexist" != "" -o "$lenerr" != "" ];then
		smfm_error_log "small_file_mul check" "$LINENO" "$valr"
	else
		smfm_success_log "small_file_mul check" "$LINENO" "$valr"
	fi
	#dmesg -c >> ${testdir}/log/small_file_muldmesg.log
}

menu "$JOB_W_R"
