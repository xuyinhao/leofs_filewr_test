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
##########################################################################
#  DESCRIPTION  :log save to file 
#  Para         : 
##########################################################################
log_to_file()
{
    local logLevel="$1"
    local message="$2"
    local lineNo="$3"
    local logFile="$4"
    
    local logTime="$(date +'%Y-%m-%d_%T')"   
    printf "[${logTime}] ${logLevel}: ${message} (${FUNCNAME[1]},${FUNCNAME[2]} ${lineNo})\n" \
 	>> "${logFile}" 2>&1
    [ $? -ne 0 ] && return 1
	return 0

}
##########################################################################
#  DESCRIPTION  :show log 
#  Para         : $1 = ERROR/INFO 则以不同stderr/stdout输出
##########################################################################
show_log()
{
    local logTime="$(date +'%Y-%m-%d_%T')"
    if [ "$1" = "ERROR" ];then
        echo "$logTime [ERROR]:$2" 1>&2
    elif [ "$1" = "INFO" ];then
        echo "$logTime  [INFO]:$2"
    else
        echo "`date +%D_%T` : $@"
    fi

}

logtofile_and_show()
{
    local logLevel="$1"
    local message="$2"
    local lineNo="$3"
    local logFile="$4"

    log_to_file "${logLevel}" "${message}" "${lineNo}" "${logFile}"
    show_log "${logLevel}" "${message}"

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
	local pattern=$1
	
	

}
##########################################################################
#  DESCRIPTION  : tar log file, the bigger idx,the newer log tar.gz file
##########################################################################
tar_log_file()
{
	local logFileFullPath="$1"
	cd "$(dirname $logFileFullPath)" > /dev/null 2>&1
	if [ $? -ne 0 ];then
		log_to_file "ERROR" "Cannot enter log dir , the log file is ${logFileFullPath}." "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
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
	[ $? -eq 0 ] && log_to_file "INFO" "Rename log file to $dstLogFileName and Create log file ${logFileFullPath} sucessed " "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
	tar --format=gnu -zcf "$tarFileName" "$dstLogFileName"
	isTarSucessed=$?
	
	# if tar failed ,then remove the old log and log the error to the new one and rm tgz
	if [ $isTarSucessed -ne 0 ];then 
		log_to_file "ERROR" "Tar old log $dstLogFileName failed." "[${SCRIPT_NAME}:${LINENO}]" "${logFileFullPath}"
		rm -rf "$tarFileName"
	else
		rm -rf "$dstLogFileName"
		log_to_file "INFO" "Tar the old $dstLogFileName to $tarFileName sucessed." "[${SCRIPT_NAME}]:${LINENO}" "${logFileFullPath}" 
	fi
	
	#check if the num of log tgz is greater than MAX_LOG_TAR
	delete_log_files "$logFileNameNoExt"
	cd - > /dev/null 2>&1 ||return 1
	return $isTarSucessed

}




##########################################################################
#  DESCRIPTION  : init log file
##########################################################################


init_log()
{
	LOG_FILE_FULL_PATH="$1"
	local retValue=0				#init falg 
	local logDir=""
	logDir=$(dirname "${LOG_FILE_FULL_PATH}")
	#make dir -p
	[ -d ${LOG_FILE_FULL_PATH} ] && show_log "ERROR" "Faile to init log file . this path is a dir" && return 1
	if [ ! -d ${logDir} ];then
		mkdir -m 770 -p "${logDir}"
	fi
	#make log file
	if [ ! -f "${LOG_FILE_FULL_PATH}" ];then 
		touch "${LOG_FILE_FULL_PATH}"
		chmod 600 "${LOG_FILE_FULL_PATH}"
		log_to_file "INFO" "Create log file ${LOG_FILE_FULL_PATH} successfully." "[${SCRIPT_NAME}:${LINENO}]" "${LOG_FILE_FULL_PATH}"
		[ $? -ne 0 ]  && return 1
	else 
		local logSize=""
		logSize=$(du -ks "$LOG_FILE_FULL_PATH"|cut -f1)
		if [ $logSize -gt ${LOG_FILE_MAXSIZE} ];then
			tar_log_file "${LOG_FILE_FULL_PATH}"
			retValue=$?
		fi
	fi
	if [ $retValue -eq 0 ];then
		return 0
	else 
		log_to_file "ERROR" "Failed to initialzing log setting." "[$SCRIPT_NAME]:${LINENO}" "${LOG_FILE_FULL_PATH}" 
	fi
	return $retValue
}

#init_log "$@"
##########################################################################
#  DESCRIPTION  :Print syslog 
#  Para     :$1 项目名 ; $2 脚本名 ; $3 成功/失败(1/0) ;$4 打印信息  
##########################################################################

syslog()
{
    local componet="$1"
    local filename="$2"
    local status="$3"
    local msg="$4"
    
    if [ "$3" -eq "0" ];then 
	status="success!"
    else
	status="failed!"
    fi

    which logger > /dev/null 2>&1
    [ "$?" -ne "0" ] && return 2;	
    
    #login_user_ip="$(who|sed 's/.*(//g;s/)//g')"
    login_user_ip=$(who |grep -oP '.*\(\K([.0-9]+)')
    exec_user="`whoami`"
    logger -t $componet -i "XYH;[$filename];${status};${exec_user};${login_user_ip}:${msg}"
    return 0

}
#syslog $@
#show_log $@
