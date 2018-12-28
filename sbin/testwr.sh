#!/bin/bash
#2017-08-28 eric_xu
#执行前需要确认:
#conf/default.conf leolayout.conf testcase.conf 是否设置
#程序 先创建冗余目录，每个目录依次执行任务，每个机器根据内存调整并发数，8G，16G... 则并发1，2任务数
if [ $# -ne 1 ];then echo "echo Usage: $0 write|check|remove|all";exit;fi
cpath0=`dirname $0`
cpaths=`cd "${cpath0}";cd "..";pwd`
if [ ! -f ${cpaths}/conf/default.conf ]||[ ! -f ${cpaths}/conf/leofslayout.conf ]|| \
[ ! -f ${cpaths}/conf/testcase.conf ]; then
    echo "conf is not exist !"
    exit 0
fi
. ${cpaths}/conf/default.conf
date1=`date +%m%d%H%M`
retlog=${cpaths}/log/ret${date1}.log	#返回日志
testconf=`cat ${cpaths}/conf/testcase.conf`
layoutconf=`cat ${cpaths}/conf/leofslayout.conf`
. ${cpaths}/bin/common
nodes=(${nodeList})
nodeNum=${#nodes[@]} 			 #根据输入的nodeList,计算client总个数
log "时间:"`date` "||  所有节点：" ${nodes[@]} "||  节点总数： " ${nodeNum}
#echo "totle nodeNum: $nodeNum"
truncate --size 0 ${cpaths}/conf/.pytask
rm -rf ${cpaths}/conf/.line*

job=0
function get_testconf {
for inum in $(seq 0 $(($laynum-1)))
do
        testdir=${testdirn[inum]}
        for testName in $testconf
        do
                exist=`echo "$testName"| grep  "#"`
        if [ "$exist" != "" ]; then
                :                                               #空语句
        else
                cmds[${job}]=$testName                   #要执行的任务放进cmds数组
                echo  $testName $testdir >> ${cpaths}/conf/.pytask      ##要执行的任务 + 执行的目录
                job=`expr $job + 1`                     #任务数
                jobbak=$job
        fi
        done
done
}
function load_task {
cmdcmd=$1
get_testconf
log  "totle task_job: $job"
for i in $(seq 1 $job)
        do
                mod=`expr ${i} % ${nodeNum}`
                mm=`cat ${cpaths}/conf/.pytask|sort|sed -n ${i}p`
                echo $mm  >> ${cpaths}/conf/.line$mod		#每个客户端 分配得到任务 line0 line1 ...
        done

}

function leoclt_cmd {
##给python 一个 cmd $1, linetask $2  , $cpaths路径 $3
for nm in $(seq 0 $((nodeNum-1)))
do
	ssh ${nodes[${nm}]} "python ${cpaths}/sbin/multiPoolTask.py $1  ${cpaths}/conf/.line$nm  ${cpaths}"  >> $retlog 2>&1  &
	log ${nodes[${nm}]}   $nm
done
wait
if [ "$cmdcmd" = "remove" ];then
	rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
fi
}
function check_conf {
echo "******confirm your conf******"
                echo 'testconf:' $testconf
                echo  'layoutconf:' $layoutconf
                echo 'nodes:' ${nodes[@]}
                read -p  "please input  y/n ? : " ret
                if [[ "$ret" == "y" || "$ret" == "Y" ||"$ret" == "yes" ]];then
                        echo "continue..."
                else
                         echo "pls check conf ..."
                        exit 0
                fi
}
function start {
echo "run job cmd: $1"
case $1 in 
	"write"|"check"|"all")
		layout
		load_task $1
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
check_conf
start $1
