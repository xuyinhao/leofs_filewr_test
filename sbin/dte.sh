#!/bin/bash
#2017-08-28 eric_xu
#执行前需要确认:
#conf/default.conf leolayout.conf testcase.conf 是否设置
#程序 先创建冗余目录，每个目录依次执行任务，每个机器根据内存调整并发数，8G，16G... 则并发1，2任务数
if [ $# -ne 1 ];then echo "echo Usage: $0 write|check|remove|all";exit;fi
cpath0=`dirname $0`
cpaths=`cd "${cpath0}";cd "..";pwd`
if [ ! -f ${cpaths}/conf/default.conf ]||[ ! -f ${cpaths}/conf/leofslayout.conf ]|| \
[ ! -f ${cpaths}/conf/testcase.conf ]||[ ! -f ${cpaths}/lib/log_tool.sh ]|| \
[ ! -f ${cpaths}/lib/kremote.sh ]; then
    show_log "ERROR" "conf is not exist !"
    exit 2
fi
# 初始化 日志，获取配置文件
. ${cpaths}/conf/default.conf
. ${cpaths}/lib/log_tool.sh
ssh_by_passwd="sh ${cpaths}/lib/kremote.sh"
#date1=`date +%m%d%H%M`
retlog=${cpaths}/log/ret${date1}.log	#返回日志
init_log "$retlog"
testconf=`cat ${cpaths}/conf/testcase.conf`
layoutconf=`cat ${cpaths}/conf/leofslayout.conf`

# 获取节点信息
. ${cpaths}/bin/common
nodesArray=(${nodeList})
nodesList=${nodeList[@]}
nodeNum=${#nodesArray[@]} 			 #根据输入的nodeList,计算client总个数
log_and_show "INFO" "${0} 节点总数: ${nodeNum};节点名:$nodesList" "$LINENO"

#check ssh node ok or not
curtime=`date +%s`;rm -rf ${cpaths}/conf/.tmp/.testfile_* > /dev/null 2>&1;mkdir -p ${cpaths}/conf/.tmp/.testfile_${curtime}
if [[ "$sshtype" == "0" ]];then
    log_info "Use ssh type : no passwd. "
	for i  in ${nodesArray[@]}
	do
		ssh -o ConnectTimeout=2 $i "which python > /dev/null  && which java > /dev/null  && ls ${cpaths}/conf/.tmp/.testfile_${curtime} > /dev/null "
		[ $? -ne 0 ] && log_and_show "ERROR" "python,java未安装或脚本未放置在共享目录或免密错误" && syslog "leofs_wr" "${0}" 1 "check env:python,java未安装或脚本未放置在共享目录或免密错误" && exit 0
	done
elif [[ "$sshtype" == "1" ]];then
    log_info "Use ssh type : passwd."
	 which expect > /dev/null 2>&1
	if [ $? -ne 0 ];then
		log_and_show "ERROR" "This node no expect!Exit." 
	else
		for i  in ${nodesArray[@]}
    	do
			$ssh_by_passwd -i $i  -p $nodepasswd -t 5  -m ssh-cmd -c "which python > /dev/null && which java > /dev/null && ls ${cpaths}/conf/.tmp/.testfile_${curtime} > /dev/null"
			[ $? -ne 0 ] && log_and_show "error" "python,java未安装或脚本未放置在共享目录或连接错误" && exit 0
		done
	fi
else
    log_and_show "ERROR" "default.conf ssh type set error type,pls check!" "$LINENO"
    exit 1
fi

#初始化索引文件(删除旧文件)
clientTaskIndexFile="${cpaths}/conf/.pytask"
truncate --size 0 $clientTaskIndexFile
rm -rf ${cpaths}/conf/.line*

##########################################################################
#  DESCRIPTION  : 获取所有测试任务并记录在 conf/.pytask 并产生 conf/.line[0-9]文件
#				  用以记录每个客户端所需要执行的任务
#  PARM         :  Null
#  Return		: 0 -- success
##########################################################################
get_job_test()
{
jobNum=0
allLayNum=${laynum}
log_and_show "INFO" """FT:${#FileTest[@]};SM_Mul:${#small_file_mul[*]};FGT:${#FGTest[@]} ;SM_single: ;MetaT: ;"""
for inum in $(seq 0 $(($allLayNum-1)))
do
	testDir=${testdirn[inum]}
	# FileTest
	for i in $(seq 0 $((${#FileTest[@]}-1)))
	do
		testName=FileTest${i}
		if [ -z "${FileTest[$i]}" ];then
			log_and_show "ERROR" "default.conf task num error!"
			exit 1
		fi
		cmds[$jobNum]=$testName
		let jobNum+=1
		echo "FileTest.sh $i $testDir" >> $clientTaskIndexFile 
		[ $? -ne 0 ] && return 1
	done
	# small_file_mul
	for j in $(seq 0 $((${#small_file_mul[@]}-1)))
	do
		testName=small_file_mul${j}
		if [ -z "${small_file_mul[$j]}" ];then
			log_and_show "ERROR" "default.conf task num error!"
            exit 1
		fi
		cmds[$jobNum]=$testName
		let jobNum+=1
		echo "small_file_mul.sh $j $testDir" >> $clientTaskIndexFile
		[ $? -ne 0 ] && return 1
	done
		
	# small_file_single
	for i in $(seq 1 ${#small_file_single[@]})
    do
        testName=small_file_single${i}
        cmds[$jobNum]=$testName
		let jobNum+=1
        echo "small_file_single.sh $i $testDir" >> $clientTaskIndexFile
		[ $? -ne 0 ] && return 1
    done
	# FGTest
    for i in $(seq 0 $((${#FGTest[@]}-1)))
    do
        testName=FGTest${i}
        cmds[$jobNum]=$testName
		let jobNum+=1
        echo "FGTest.sh $i $testDir " >> $clientTaskIndexFile
		[ $? -ne 0 ] && return 1
    done
	# test_multhr_meta
	for i in $(seq 1 ${#test_multhr_meta[@]})
    do
        testName=test_multhr_meta${i}
        cmds[$jobNum]=$testName
		let jobNum+=1
        echo "test_multhr_meta.sh $i $testDir"  >> $clientTaskIndexFile
		[ $? -ne 0 ] && return 1
    done
#echo 2: ${FileTest[*]}
task_all_info=${cmds[@]}
done

show_log "INFO"  "all task info:${task_all_info}" 
return 0
}


#加载任务 生成 .line[0-9]文件
##每个客户端 从 line0 line1 ... 文件获取相应的文件
load_task() {
get_job_test
log_and_show "INFO"  "totle task_job: $jobNum" 
for i in $(seq 0 $(($jobNum-1)))
	do
		declare -i clientMod
		clientMod=`expr ${i} % ${nodeNum}`
		taskSetToClients=`cat $clientTaskIndexFile|sort|sed -n $((${i}+1))p`
		echo "$taskSetToClients"  >> ${cpaths}/conf/.line$clientMod		#每个客户端 分配得到任务 line0 line1 ...
	done
}



#每个节点分配任务并开始执行任务
##给python 一个 cmd $1, linetask $2  , $cpaths路径 $3
function leoclt_cmd {
cmdExec=$1				#执行write,check,remove or all
#clientTaskNum
for clientTaskNum in $(seq 0 $((nodeNum-1)))
do
	sleep 0.3
	if [ $sshtype -eq 0 ];then
		ssh ${nodesArray[${clientTaskNum}]} 'python '${cpaths}'/sbin/multiPoolTask.py '$1'  '${cpaths}'/conf/.line'${clientTaskNum}' '${cpaths}' > /dev/null ' &
#>> '${retlog}.${nodesArray[${clientTaskNum}]}' 2>&1 '  &
		if [ $? -ne 0 ];then 
			log_and_show "error"  "ssh ${nodesArray[${clientTaskNum}]} failed ;" $LINENO
			#exit 1
		fi
	else
		$ssh_by_passwd -i ${nodesArray[${clientTaskNum}]} -p $nodepasswd -m ssh-cmd -c "python ${cpaths}/sbin/multiPoolTask.py $1  ${cpaths}/conf/.line${clientTaskNum}  ${cpaths}  >> $retlog 2>&1 " & 
		if [ $? -ne 0 ];then
            log_and_show "error"  "ssh ${nodesArray[${clientTaskNum}]} failed ;" $LINENO
            #exit 1
        fi
	fi
	log_and_show "INFO"  "ssh ${nodesArray[${clientTaskNum}]} exec and lineNum is: $clientTaskNum" "$LINENO" 
done
wait
if [ "$cmdExec" = "remove" ];then
	rmdir ${testdir}/log > /dev/null 2>&1
	rmdir ${testdir}/log > /dev/null 2>&1
    rmdir ${testdir} > /dev/null 2>&1
	log_info "rmdir ${testdir} " "$LINENO"
fi
log_and_show "INFO" "leoclt_wr finished ~ "
}

#确认配置文件内容，是否根据实际设置。需要人为判断
function check_conf {
echo "******confirm your conf******"
                echo 'testconf:' $testconf
                echo  'layoutconf:' $layoutconf
                echo 'nodesList:' $nodesList
                read -p  "please input  y/n ? : " ret
                if [[ "$ret" == "y" || "$ret" == "Y" ||"$ret" == "yes" ]];then
                        echo "continue..."
                else
                         echo "pls check conf ..."
                        exit 0
                fi
}

## main主函数， start函数
function wr_start {
log_and_show "INFO" "run job cmd: $1"
case $1 in 
	"write"|"check"|"all")
		layout
		load_task 
		leoclt_cmd $1
		grep fail $retlog
		;;
	"remove")
		layout
		load_task $1
		leoclt_cmd $1
		;;
	"test")
		layout
		;;
	*)
		echo "Usage: $0 write|check|remove|all"
esac
}
#check_conf
wr_start "$1" &
