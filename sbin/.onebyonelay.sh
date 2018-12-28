#!/bin/bash
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
nodeNum=${#nodes[@]}  #根据输入的nodeList,计算client总个数
date1=`date +%m%d%H%M`
retlog=${cpaths}/ret/ret${date1}.log
#mkdir -p ${testdir}/log
#rm -rf ${testdir}/log

function leofstestall {
job=0
for testName in $testconf
do
  exist=`echo "$testName"| grep  "#"`
  if [ "$exist" != "" ]; then
     echo 1 > /dev/null
  else
     cmds[${job}]=$testName  #要执行的任务放进cmds数组
 #    echo ${cmds[${job}]}
     job=`expr $job + 1`
     jobbak=$job
  fi
done
#bi=`expr $job / $nodeNum` #计算任务数和client的比值


tasknum=`expr $nodeNum \* 3`
cyc=1
while [[ $job -ge $tasknum ]]  #让每个客户端先执行3个任务(while)，执行完再执行剩下的任务
do 
	lasttask=`expr ${tasknum} \* ${cyc} - 1`
	fcyc=`expr $(($cyc-1)) \* 3`
	for j in $(seq $fcyc $lasttask)
	do
		 mod=`expr ${j} % ${nodeNum}`
		echo "start run  ${cmds[$j]} task..." 
		#echo "start run  ${cmds[$j]} task..." >> $retlog
	     ssh ${nodes[${mod}]} "sh ${cpaths}/bin/${cmds[$j]} $1 $2"  >> $retlog 2>&1  &
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
             #echo "start run  ${cmds[$j]} task..." >> $retlog
	     ssh ${nodes[${mod}]} "sh ${cpaths}/bin/${cmds[$j]} $1 $2" >> $retlog  2>&1 &
             #echo $mod
	     # echo  $j
           done
           wait
        fi
#	cat $retlog|sort
}
function sa {
for inum in $(seq 0 $(($laynum-1)))
do
testdir=${testdirn[inum]}
 echo $testdir 
 echo -e "\n $testdir \n" >> $retlog
 echo "$testdir" > ${cpaths}/conf/.tmptestdir${inum}
leofstestall $1 $inum
if [ "$1" = "remove" ];then  
	rmdir ${testdir}/log > /dev/null 2>&1 
	rmdir ${testdir} > /dev/null 2>&1 
fi
#start $1
done
cat $retlog
}

function start {
echo $1
case $1 in 
	"write"|"check"|"all")
		layout
		sa $1
		;;
	"remove")
		layout
		sa $1
		;;
	*)
		echo "Usage: $0 write|check|remove|all"
esac
}
start $1
