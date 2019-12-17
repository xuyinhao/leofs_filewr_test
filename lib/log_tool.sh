#!/bin/bash
##########################
## 说明：
## 	log tools , script 
#########################

#设置变量的属性
declare  TMP_PATH='/tmp'
declare -i LOG_FILE_MAXSIZE=1024		#max log file size is 1M ($SIZE * 1024B)
declare -i MAX_LOG_TAR=2
declare	LAST_TIME=""
declare LOG_FILE_FULL_PATH=""
declare SCRIPT_NAME="log_tool.sh"

#日志属性
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf #> /dev/null 2>&1

##########################################################################
#  DESCRIPTION  :log save to file 
#  Para         : $1 logLevel $2:msg $3:lineNo  ($4: logfilepath)
#				 如果初始化日志有path1,且$4 为空，则使用path1
##########################################################################
log()
{
    local logLevel="$1"
    local message="$2"
    local lineNo="$3"
	if [[ -z $LOG_FILE_FULL_PATH && -z $4 ]];then
		local logFile=/tmp/tmp_${SCRIPT_NAME}.log
    elif [ ! -z $4 ];then
		local logFile=$4
	else
		local logFile=$LOG_FILE_FULL_PATH
	fi
    local logTime="$(date +'%Y-%m-%d_%T')"   
    printf  "[${logTime}] ${logLevel}: ${message} (${FUNCNAME[2]};${lineNo})\n" >> "${logFile}" 2>&1
    [ $? -ne 0 ] && return 1
	return 0

}

log_debug()
{
	local lineNo=$2
	local log_full_path="$3"
	local LOG_LEVEL=$LogLevel
	if [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -gt 2 ]];then
		log "DEBUG" "$1" "$lineNo" "$log_full_path"
	elif [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -le 2 ]];then
		:
	else
		log "DEBUG" "$1" "$lineNo" "$log_full_path"
	fi
}

log_warn()
{
    local lineNo=$2
	local log_full_path="$3"
	local LOG_LEVEL=$LogLevel
	if [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -gt 1 ]];then
    	log "WARN" "$1" "$lineNo" "$log_full_path"
	elif [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -le 1 ]];then
		:
    else
		log "WARN" "$1" "$lineNo" "$log_full_path"
	fi
}

# $1:msg   $2:lineno $3: logpath
log_info()
{
    local lineNo=$2
	local log_full_path="$3"
	local LOG_LEVEL=$LogLevel
    if [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -gt 0 ]];then
    	log "INFO" "$1" "$lineNo" "$log_full_path"
    elif [[ ! -z "$LOG_LEVEL" && $LOG_LEVEL -le 0 ]];then
		:
	else
	    log "INFO" "$1" "$lineNo" "$log_full_path"
	fi
}

log_error()
{
    local lineNo=$2
	local log_full_path="$3"
    log "ERROR" "$1" "$lineNo" "$log_full_path"

}
##########################################################################
#  DESCRIPTION  :show log 
#  Para         : $1 = ERROR/INFO 则以不同stderr/stdout输出
##########################################################################
show_log()
{
    local logTime="$(date +'%Y-%m-%d_%T')"
    if [ "$1" = "ERROR" -o "$1" = "error" ];then
        echo "$logTime [ERROR]:${2}" 1>&2
    elif [ "$1" = "INFO" -o "$1" = "info" ];then
        echo "$logTime  [INFO]:${2}"
    else
        echo "`date +%D_%T` : $@"
    fi

}

log_and_show()
{
    local logLevel="$1"
    local message="$2"
    local lineNo="$3"
    local logFile="$4"

    log "${logLevel}" "${message}" "${lineNo}" "${logFile}"
    show_log "${logLevel}" "${message}" "${lineNo}"

}
log_and_echo()
{
	log_and_show "$@"
}
#log_and_show "$@"
##########################################################################
#  DESCRIPTION  : get log last mod time ;
# 	 parm  		: $1 : log file
##########################################################################
get_last_time()
{
	local logFile="$1"
	local dateFmt=""
	dateFmt=$(stat $logFile -c "%y")
	LAST_TIME=$(date -d "${dateFmt}" +'%Y-%m-%d_%H-%M-%S')
}

delete_log_files()
{
	cd "$(dirname $LOG_FILE_FULL_PATH)" > /dev/null 2>&1
	local pattern=$1
	ret=($(ls -r|grep -E "^${pattern}.[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"|grep -e  "tgz$" -e "log$"|sed -n "$((${MAX_LOG_TAR}+1)),$"p))
	 ## awk -v max=$MAX_LOG_TAR 'NR>max {print $1}
	len_ret=${#ret[@]}
	if [ $len_ret -gt 0 ];then
		log_info "delete $len_ret redundant log file,keep $MAX_LOG_TAR files" "$LINENO"
		log_debug "del_file=${ret[*]}" $LINENO
	#	rm -rf $ret > /dev/null 2>&1
	fi
}
##########################################################################
#  DESCRIPTION  : tar log file, the bigger idx,the newer log tar.gz file
##########################################################################
tar_log_file()
{
	local logFileFullPath="$1"
	cd "$(dirname $logFileFullPath)" > /dev/null 2>&1
	if [ $? -ne 0 ];then
		log "ERROR" "Cannot enter log dir , the log file is ${logFileFullPath}." "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
		return 1
	fi
	
	local -i isTarSucessed=1
	local logFileName=""
	logFileName=$(basename "$logFileFullPath")
	local logFileNameNoExt=${logFileName%.*}	 #删除日志名右边第一个.后的字符
	local logFileExt=${logFileName##*.}			 #删掉最后一个 .  及其左边的字符
	get_last_time "$logFileFullPath"
	if [ $? -ne 0 ];then
		LAST_TIME=$(date  +'%Y-%m-%d_%H-%M-%S')
	fi
	
	local dstLogFileName="${logFileNameNoExt}.${LAST_TIME}.${logFileExt}"
	local tarFileName="${logFileNameNoExt}.${LAST_TIME}.tgz"
	
	#rename old log file and touch a new logFile
	mv -f "$logFileName" "$dstLogFileName"
	touch "${logFileFullPath}" && chmod 700 "${logFileFullPath}"
	[ $? -eq 0 ] && log "INFO" "Rename log file to $dstLogFileName and Create log file ${logFileFullPath} sucessed " "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
	tar --format=gnu -zcf "$tarFileName" "$dstLogFileName"
	isTarSucessed=$?
	
	# if tar failed ,then remove the old log and log the error to the new one and rm tgz
	if [ $isTarSucessed -ne 0 ];then 
		log "ERROR" "Tar old log $dstLogFileName failed." "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
		rm -rf "$tarFileName"
	else
		rm -rf "$dstLogFileName"
		log "INFO" "Tar the old $dstLogFileName to $tarFileName sucessed." "[${SCRIPT_NAME}]:${LINENO}" "${logFileFullPath}" 
	fi
	
	#check if the num of log tgz is greater than MAX_LOG_TAR
	delete_log_files "$logFileNameNoExt"
	cd - > /dev/null 2>&1 ||return 1
	return $isTarSucessed

}

##########################################################################
#  DESCRIPTION  : init log file
#  Parm 		: $1: 日志文件全路径，如果文件过大则tar压缩
#				: $2: 可选，日志最多保留的tar个数。默认20个
##########################################################################
init_log()
{
	LOG_FILE_FULL_PATH="$1"
	if [ $# -gt 1 ];then 
		MAX_LOG_TAR=$2
	fi
	local retValue=0				#init falg 
	local logDir=""
	logDir=$(dirname "${LOG_FILE_FULL_PATH}")
	#make dir -p
	[ -d ${LOG_FILE_FULL_PATH} ] && show_log "ERROR" "Faile to init log file . this path is a dir" && return 1
	if [ ! -d ${logDir} ];then
		mkdir -m 770 -p "${logDir}" || return 1
	fi
	#make log file
	if [ ! -f "${LOG_FILE_FULL_PATH}" ];then 
		touch "${LOG_FILE_FULL_PATH}"
		chmod 600 "${LOG_FILE_FULL_PATH}"
		log "INFO" "Create log file ${LOG_FILE_FULL_PATH} successfully." "[${SCRIPT_NAME}:${LINENO}]" "${LOG_FILE_FULL_PATH}"
		[ $? -ne 0 ]  && return 1
	else 
		local logSize=$(du -ks "$LOG_FILE_FULL_PATH"|cut -f1)
		if [ $logSize -gt ${LOG_FILE_MAXSIZE} ];then
			tar_log_file "${LOG_FILE_FULL_PATH}"
			retValue=$?
		fi
	fi
	if [ $retValue -eq 0 ];then
		return 0
	else 
		log "ERROR" "Failed to initialzing log setting." "[$SCRIPT_NAME]:${LINENO}" "${LOG_FILE_FULL_PATH}" 
	fi
	return $retValue
}

#init_log "$@"
##########################################################################
#  DESCRIPTION  :Print syslog 
#  Para     :$1 项目名 ; $2 脚本名 ; $3 成功/失败(1/0) ;$4 打印信息  
#  Return    : 0 -- success ; not 0 -- failure
##########################################################################
syslog()
{
    local componet="$1"
    local filename="$2"
    local status="$3"
    local msg="$4"
    
    if [[ "$3" == "0" ]];then 
	status="success"
    else
	status="failed"
    fi

    which logger > /dev/null 2>&1
    [ "$?" -ne "0" ] && return 2;	
    
    #login_user_ip="$(who|sed 's/.*(//g;s/)//g')"
    login_user_ip=$(who -m|grep -oP '.*\(\K([.0-9]+)')
    exec_user="`whoami`"
    logger -t $componet -i "${projectName}[$filename];${status};${exec_user};${login_user_ip}:${msg}"
    return 0

}
#syslog $@
