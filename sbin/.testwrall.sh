#!/bin/bash
#2017-08-28 eric_xu
#执行前需要确认:
#conf/default.conf leolayout.conf testcase.conf 是否设置
#先创建冗余目录，每个目录依次执行任务（除了FileTest4（2T)),然后并发执行2T任务
cpath0=`dirname $0`
cpaths=`cd "${cpath0}";cd "..";pwd`
#echo $cpaths
if [ ! -f ${cpaths}/conf/default.conf ]||[ ! -f ${cpaths}/conf/leofslayout.conf ]|| \
[ ! -f ${cpaths}/conf/testcase.conf ]; then
    echo "conf is not exist !"
    exit 0
fi
. ${cpaths}/conf/default.conf
#. ${cpaths}/bin/common
testconf=`cat ${cpaths}/conf/testcase.conf`
layoutconf=`cat ${cpaths}/conf/leofslayout.conf`
#cmds=()
. ${cpaths}/bin/common
nodes=(${nodeList})
#echo ${nodes}
nodeNum=${#nodes[@]} 			 #根据输入的nodeList,计算client总个数
date1=`date +%m%d%H%M`
retlog=${cpaths}/log/ret${date1}.log	#返回日志
#mkdir -p ${testdir}/log
#rm -rf ${testdir}/log
function leofstestall {
job=0
for testName in $testconf
do
	exist=`echo "$testName"| grep  "#"`
  	exist2T=`echo "$testName"|grep "^FileTest4.sh"` #把2T的任务 统一到最后执行
  	if [ "$exist" != "" ]; then
     		:						#空语句
  	elif [ "$exist2T" != "" ];then
     		cmd2T=$testName
  	else
     		cmds[${job}]=$testName 			 #要执行的任务放进cmds数组
 		#echo ${cmds[${job}]}
     		job=`expr $job + 1` 			#任务数
     		jobbak=$job
  	fi
done
#bi=`expr $job / $nodeNum` #计算任务数和client的比值

tasknum=`expr $nodeNum \* 3`
cyc=1
while [[ $job -ge $tasknum ]]  			#让每个客户端先执行3个任务(while)，执行完再执行剩下的任务
do 
	lasttask=`expr ${tasknum} \* ${cyc} - 1`
	fcyc=`expr $(($cyc-1)) \* 3`
	for j in $(seq $fcyc $lasttask)
	do
		mod=`expr ${j} % ${nodeNum}`
		echo "start run  ${cmds[$j]} task..." 
		echo "start run  ${cmds[$j]} task..." >> $retlog
	     	ssh ${nodes[${mod}]} "source /etc/profile;sh ${cpaths}/bin/${cmds[$j]} $1 $2"  >> $retlog 2>&1  &
        done
	wait 
	let cyc+=1
	let job=${job}-${tasknum}
done
if [ $job -ge 1 ];then
	for j in $(seq  $((${jobbak}-$job)) $(($jobbak-1))) #任务数小于客户端*3，则客户端依次执行一个任务
           do
	     	mod=`expr ${j} % ${nodeNum}`
	     	echo "start run  ${cmds[$j]} task..." 
             	echo "start run  ${cmds[$j]} task..." >> $retlog
	     	ssh ${nodes[${mod}]} "source /etc/profile;sh ${cpaths}/bin/${cmds[$j]} $1 $2" >> $retlog  2>&1 &
             	#echo $mod
	     	# echo  $j
           done
           wait
fi
#	cat $retlog|sort
}

function for2T {			#为不同冗余模式的2T文件准备
if [ "${cmd2T}" = "" ];then
	exit 0
fi
tasknum=`expr $nodeNum \* 3` 
cyc=1
job=$laynum  				#冗余目录的数量
jobbak=$laynum
while [[ $job -ge $tasknum ]]  		#让每个客户端一次最多先执行3个冗余目录(while)，执行完再执行剩下的任务
do
        lasttask=`expr ${tasknum} \* ${cyc} - 1`
        fcyc=`expr $(($cyc-1)) \* 3`
        for lnum in $(seq $fcyc $lasttask)
        do
		testdir=${testdirn[lnum]}
                echo $testdir 
                echo -e "\n${testdir}" >> $retlog
                echo "$testdir" > ${cpaths}/conf/.tmptestdir${lnum}
                 mod=`expr ${lnum} % ${nodeNum}`
                echo "start run  ${cmd2T} task..." 
                echo "start run  ${cmd2T} task..." >> $retlog
             ssh ${nodes[${mod}]} "source /etc/profile;sh ${cpaths}/bin/${cmd2T} $1 $lnum"  >> $retlog 2>&1  &
        done
        wait
        let cyc+=1
        let job=${job}-${tasknum}
done
if [ $job -ge 1 ];then
        for lnum in $(seq  $((${jobbak}-$job)) $(($jobbak-1))) #冗余目录总数小于客户端*3，则客户端依次执行
           do
             	testdir=${testdirn[lnum]}
             	echo $testdir 
             	echo -e "\n${testdir}" >> $retlog
             	echo "$testdir" > ${cpaths}/conf/.tmptestdir${lnum}

	     	mod=`expr ${lnum} % ${nodeNum}`
             	echo "start run  ${cmd2T} task..." 
            	echo "start run  ${cmd2T} task..." >> $retlog
             	ssh ${nodes[${mod}]} "source /etc/profile;sh ${cpaths}/bin/${cmd2T} $1 $lnum" >> $retlog  2>&1 &
             	#echo $mod
             	# echo  $j
           done
           wait
fi
if [ "$1" = "remove" ];then
	for lnum in $(seq 0 $(($laynum-1)))
        do
        testdir=${testdirn[lnum]}
	rmdir ${testdir}/log > /dev/null 2>&1 		#如果是空文件夹则删除
	rmdir ${testdir} > /dev/null 2>&1
	done
fi
cat $retlog
}
function sa {
for inum in $(seq 0 $(($laynum-1)))
do
	testdir=${testdirn[inum]}
	echo $testdir 
 	echo -e "\n${testdir}" >> $retlog
 	echo "$testdir" > ${cpaths}/conf/.tmptestdir${inum}
	leofstestall $1 $inum
	if [ "$1" = "remove" ];then  
		rmdir ${testdir}/log > /dev/null 2>&1 
		rmdir ${testdir} > /dev/null 2>&1 
	fi
#start $1
done
#cat $retlog
}

#  write\check
## all = write + check
## remove = delete 
function start {
echo $1
case $1 in 
	"write"|"check"|"all")
		layout
		sa $1
		for2T $1
		;;
	"remove")
		layout
		sa $1
		for2T $1
		;;
	*)
		echo "Usage: $0 write|check|remove|all"
esac
}
start $1
