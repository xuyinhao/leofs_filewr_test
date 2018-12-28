#!/bin/bash
# 此脚本为块设备start脚本：
#先在conf/default.conf设置 块设备的相关配置
#conf/leofslayout.conf 设置需要的冗余
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
#${cpath}/conf/leofslayout.conf
. ${cpath}/bin/common
. ${cpath}/bin/blkcommon

function inita1 {
  echo -e "\033[33m******initing some info******\033[0m" 
  blkwrlog=${cpath}/log/blkwr.log
  blkelog=${cpath}/log/blkerror.log
  blksteplog=${cpath}/log/blkstep.log
  layoutconf=`cat ${cpath}/conf/leofslayout.conf`
  nodes=(${nodeList})
  #echo ${nodes}
  nodeNum=${#nodes[@]}
  vss=(${volsize})
  vsNum=${#vss[@]}
  #echo ${layoutnamen[1]} ##没有空格名字
  #echo ${laylist[1]}	#有空格，设置
  blklayout
  #lay=(${laylist})
  layoutNum=${laynum}
 #echo ${layoutNum}
  spanuml=(${spanum});spansizel=(${spansize});blksizel=(${blksize})
  spn=${#spanuml[@]};sps=${#spansizel[@]};bks=${#blksizel[@]};
  checkclient
  echo -e "\033[33m******initing finished******\033[0m"
}
blknum=0
#创建块设备 并检查块设备info + 创建成功的块总数和预期总数做对比
function CREATE {
  echo -e "\033[33m******creating src blkdev******\033[0m"
  #layout
  #rm -rf ${cpath}/conf/.tmp/bdsrc ${cpath}/conf/.tmp/*blk* ${cpath}/conf/.tmp/tmparg
  futurenum=`expr $spn \* $sps \* $bks`
  echo "will create $futurenum blkdev"
  beginblknum=`showallblkdev`
  echo "exist blk num now:$beginblknum"
for sn in $spanum
do
	for ss in $spansize
	do
		for bs in $blksize
		do	
		vsmod=`expr $blknum % $vsNum`
		layoutmod=`expr $blknum % ${layoutNum}`
		bn="${sn}_${ss}_${bs}_${vss[vsmod]}_${layoutnamen[layoutmod]}"
		createblkdev $sn $ss $bs ${vss[vsmod]} $bn ${laylist[layoutmod]}
	#	echo "$sn $ss $bs ${vss[vsmod]} $bn ${laylist[layoutmod]}"
		showblkinfo $bid $sn $ss $bs ${vss[vsmod]} $bn ${laylist[layoutmod]}
		let blknum+=1
		done
	done
done
  endblknum=`showallblkdev`
  echo  "end blk num :$endblknum"
  creatednum=`expr $endblknum - $beginblknum`
  #echo "created blkdev num:$creatednum"
if [ $futurenum !=  $creatednum ];then
	echo "create blkdev  failed;expired num :$futurenum ,created num: $creatednum"
else
	echo "created success :total created num :$creatednum"
fi
echo -e "\033[33m******creating finished******\033[0m"
}

#map到客户端上,并检查map信息和fdisk -l 与 ls /dev/leobd1dx 是否存在
function MAP {

  echo -e "\033[33m******mapping ${1} blkdev******\033[0m"
  #echo ${clientidlist}  
  #echo ${clientidNum} 
  #echo ${clientid[x]} 客户端id
  #echo ${clientnode[x]} 客户端nodename
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
	cmod=`expr $bid % ${clientidNum}`
	mapclient $bid ${clientid[cmod]}
	#echo $bid ${clientid[cmod]}
	checkmap $bid ${clientnode[cmod]}  
	if [ "$fdiskreturn" = "" ]||[ "$lsreturn" = "" ]||[ "$mapcreturn" != "${clientid[cmod]}" ];then
		echo -e "check map $bid to ${clientnode[cmod]} \033[31mfailed\033[0m"
		echo "fdiskreturn:$fdiskreturn; lsreturn:$lsreturn mapcreturn:$mapcreturn"
	else
		echo -e "check map $bid to ${clientnode[cmod]} \033[32mpass\033[0m"
	fi
done
  echo -e "\033[33m******mapping finished******\033[0m"
}

#unmap ，并检查
function UNMAP {
  echo -e "\033[33m******unmapping $1 blkdev******\033[0m"
  #echo ${clientidlist}
  #echo ${clientidNum}
  #echo ${clientid[1]}
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        unmapclient $bid ${clientid[cmod]}
        #echo $bid ${clientid[cmod]}
        checkmap $bid ${clientnode[cmod]}
        if [ "$fdiskreturn" != "" ]||[ "$lsreturn" != "" ]||[ "$mapcreturn" != "" ];then
                echo -e "check $bid unmap from ${clientnode[cmod]} \033[31mfailed\033[0m"
                echo "fdiskreturn:$fdiskreturn; lsreturn:$lsreturn mapcreturn:$mapcreturn"
        else
                echo -e "check $bid unmap from ${clientnode[cmod]} \033[32mpass\033[0m"
        fi
done
  echo -e "\033[33m******unmapping finished******\033[0m"
}

#fdisk fo src blkdev
function fdiskf {
  echo -e "\033[33m******fdisking src blkdev******\033[0m"
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid fdisk"  &
        flag=$?
        checkok $? fdisk$bid
done
wait
  echo -e "\033[33m******fdisking finished******\033[0m"
}

#mkfs for src blkdev
function mkfsf {

echo -e "\033[33m******mkfs src blkdev******\033[0m"
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid mkfs"   &
        flag=$?
        checkok $? mkfs$bid

done
wait
echo -e "\033[33m******mkfs src finished******\033[0m"
}

#mount for src\clone\snapshot blkdev,use $1 
function mountf {
echo -e "\033[33m******mounting $1 blkdev******\033[0m"
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid mount"   &
        flag=$?
        checkok $? mount$bid

done
wait
echo -e "\033[33m******mounting $1 finished******\033[0m"
}
#src startmount：1.fdisk  2.mkfs 3.mount
function STARTMOUNT {
echo -e "\033[33m******startmount src blkdev******\033[0m"
#fdisk
fdiskf
wait
mkfsf
wait
mountf src
wait
}

#delfdisk for src blkdev(for single test)
function delfdiskf {
echo -e "\033[33m******delete src blkdev partion******\033[0m"
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid delfdisk" &
        flag=$?
        checkok $? fdisk$bid
done
wait
echo -e "\033[33m******delete partion finished******\033[0m"
}

#umount for src\clone\snapshot ,use $1 = src\clone\snapshot
function STARTUMOUNT {

echo -e "\033[33m******startumount $1 blkdev******\033[0m"
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid umount"  &
        flag=$?
        checkok $? fdisk$bid
done
wait
echo -e "\033[33m******umount finished******\033[0m"
#删除分区？
#for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
#do
#        cmod=`expr $bid % ${clientidNum}`
#        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid delfdisk" &
#        flag=$?
#        checkok $? fdisk$bid
#done
#wait
}

#写大文件，size为块设备的60%;小文件30% 1w个 100B
#filetask=`expr ${clientidNum} \* 5 > /dev/null  2>&1` #每个客户端并发最多5个任务
function tasking {
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
    cmod=`expr $bid % ${clientidNum}`
   # sed -i s/"^${bid}_ "/xxxx/g ${cpath}/conf/.tmp/wrtmp > /dev/null 2>>$blkelog
    rrand=`expr $(($bid +  $RANDOM)) % ${clientidNum} + 1` # 修改write/read 类型个数（1.bigf 2.smallf  \\\3.smallmulf）
    
    for i in $(seq 0 $((${clientidNum}-1)))
    do
        if [ $cmod = "$i" ];then
                echo "$bid" >> ${clientnode[cmod]}
        fi
    done
#   echo "${bid}_ $rrand" >> ${cpath}/conf/.tmp/wrtmp${2}
  #  echo "testwrite $bid"
 #   ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid wfile${rrand} ${2}" &
  #  sleep 0.2   #延时，防止tmparg 写入失败
 #   ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh rfile" &
done
   for node in ${clientnodelist}
    do
        num=0
        for i in `cat $node`
        do
                eval ${node}[$num]=${i}
                let num+=1
        done
    done

}
function nota {
   for node in ${clientnodelist}
    do
        num=0
        for i in `cat $node`
        do
                eval ${node}[$num]=${i}
                let num+=1
        done
    done

}
inita1
nota
#tasking
#$1 = nodename 
function taskread {
 	bid=$2
	ttt=$1
        #cmod=`expr $bid % ${clientidNum}`
        rrand=`cat ${cpath}/conf/.tmp/wrtmp${3}|grep "^${bid}_ "|awk '{print $2}'`
        echo "testread $bid"
        ssh ${ttt} "sh ${cpath}/bin/mfmu.sh $bid rfile${rrand} ${3}" &
        #sleep 0.2
}

function nowtask {
ttt=${1}
num=`ps aux|grep "ssh $ttt"|grep -v "grep"|wc -l`
echo $ttt
echo $num
while [ ${num} -le 5 ]
do
 taskread ${ttt} ${#${node}[num]}
 #let  ${num}+=1
echo ${ttt} ${node}[$n]
let  n=$n+$num
if [ $num -gt 10 ];then
 return 8
 break
fi
done
}
nowtask node102
nowtask node103
nowtask node105
#writefile for src\clone\snapshot,use $1=src\clone\snapshot $2= clone(second write\read args
function WRITEFILE {
echo -e "\033[33m******writingfile test *****\033[0m"
#$! src/clone/   $2 src/clone :克隆，第二次写读需要的文件
#rm -rf ${cpath}/conf/.tmp/tmparg${2}  ${cpath}/conf/.tmp/wrtmp${2}
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务
#echo $filetask
waitnum=1;num=0
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
    cmod=`expr $bid % ${clientidNum}`
   # sed -i s/"^${bid}_ "/xxxx/g ${cpath}/conf/.tmp/wrtmp > /dev/null 2>>$blkelog
    rrand=`expr $(($bid +  $RANDOM)) % 3 + 1` # 修改write/read 类型个数（1.bigf 2.smallf  \\\3.smallmulf）
    echo "${bid}_ $rrand" >> ${cpath}/conf/.tmp/wrtmp${2}
    echo "testwrite $bid"
    ssh	${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid wfile${rrand} ${2}" &
    sleep 0.2	#延时，防止tmparg 写入失败
 #   ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh rfile" &
    if [ "$waitnum" = "$filetask" ];then
	wait
	waitnum=0
    fi
    let waitnum+=1	
done
wait
echo -e "\033[33m******write finished******\033[0m"
}

#读块设备的内容
#readfile for src/clone/snapshot ,$1 、 $2
function READFILE {
echo -e "\033[33m******readfile testing******\033[0m"
waitnum=1
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
	cmod=`expr $bid % ${clientidNum}`
	rrand=`cat ${cpath}/conf/.tmp/wrtmp${2}|grep "^${bid}_ "|awk '{print $2}'`
	echo "testread $bid"
	ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid rfile${rrand} ${2}" &
	#sleep 0.2
     if [ "$waitnum" = "$filetask" ];then
        wait
        waitnum=0
    fi
    let waitnum+=1
done
wait
echo -e "\033[33m******readfile test finished******\033[0m"
}

#remove blkdev mount file for src/clone,use $1
function REMOVEFILE {
echo -e "\033[33m******remove ${1} blkdev file ******\033[0m"
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务
for bid in `cat ${cpath}/conf/.tmp/bd${1}|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        ssh ${clientnode[cmod]} "rm -rf /mnt/blk/leobd1d${bid}/*" &
     if [ "$waitnum" = "$filetask" ];then
        wait
        waitnum=0
    fi
    let waitnum+=1
done
wait

}
#客户端所有的块设备是否和show blkdev to client map一致
function SHOWCLIENTMAP {
echo -e "\033[33m******checking clientdev&mds show******\033[0m"
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务

for i in $(seq 0  $((${clientidNum}-1)))
do
echo  ${clientnode[i]}
cltmaptotal=`ssh ${clientnode[i]} 'fdisk -l |grep "Disk /dev/leobd1d*"'|wc -l`
cltlist=`ssh ${clientnode[i]} "fdisk -l |grep 'Disk /dev/leobd1d*'"|awk -F ":" '{print $1}'|cut -b 18-|sort` #需要排序保证和mds一致
showclientmapinfo ${clientid[i]}
cltlist=`echo ${cltlist}|tr -t '\n' ' '`
#echo $cltlist
blkList=`echo -e $blkList|tr -t '\n' ' '`
#echo $blkList
#echo $total
if [ "$cltmaptotal" != "$total" ]||[ "$cltlist" != "$blkList" ];then
	echo -e "check ${clientnode[i]} show client map info \033[31mfailed\033[0m"
	echo "cltmaptotal:$cltmaptotal  cltlist:$cltlist" >> $blkelog
	echo "mdstotal:$total  mdsblkList:$blkList" >> $blkelog
else
	echo -e "check ${clientnode[i]} show client map info \033[32mpass\033[0m"
	echo "check check ${clientnode[i]} show client map info" >> $blksteplog
	echo "cltmaptotal:$cltmaptotal  cltlist:$cltlist" >> $blksteplog
fi
done 
#clttotal=`fdisk -l |grep "Disk /dev/leobd1d*"|awk -F ":" '{print $1}'|cut -b 18-`

}

#resize for expandblkdev
function resizef {
echo -e "\033[33m******resize src blkdec size******\033[0m"

for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
        cmod=`expr $bid % ${clientidNum}`
        echo "resize $bid"
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid resizef" &
	if [ $? != "0" ];then
		echo "$bid  ${clientnode[cmod]}   failed"
	fi
done
wait
}
function EXPANDBLKDEV {
#mds扩展分区
echo -e "\033[33m******expanding blkdev size ******\033[0m"
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
    expanddev  $bid
    if [ $? != "0" ];then
	echo -e "expan devblk $bid \033[31mfailed\033[0m"
    else
	echo -e "expan devblk $bid from ${oldbsize}MB to ${newbsize}MB \033[32mpass\033[0m"
    fi
done
STARTUMOUNT src
delfdiskf
wait
fdiskf
wait
resizef
wait
mountf src
wait
READFILE src
#umount 挂载
#删除分区
#创建分区
#resize分区
#mount 挂载
#读取文件内容
#
}

#克隆块设备
function cloneread {
echo -e "\033[33m******reading clone blkdev file******\033[0m"
waitnum=1
filetask=`expr ${clientidNum} \* 5` #每个客户端并发最多5个任务
for bid in `cat ${cpath}/conf/.tmp/bds$1|awk '{print $1}'`
do
	bidsrc=`cat ${cpath}/conf/.tmp/bds$1|grep $bid|awk '{print $2}'|awk -F "_" '{print $1}'`
        cmod=`expr ${bidsrc} % ${clientidNum}`
        rrand=`cat ${cpath}/conf/.tmp/wrtmp|grep "^${bidsrc}_ "|awk '{print $2}'`
        echo "testread $bid"
        ssh ${clientnode[cmod]} "sh ${cpath}/bin/mfmu.sh $bid rfile${rrand}" &
        #sleep 0.2
     if [ "$waitnum" = "$filetask" ];then
        wait
        waitnum=0
    fi
    let waitnum+=1
done
wait
echo -e "\033[33m******reading clonefile finished******\033[0m"
}
#直接mountf $1
function MOUNTSC {
mountf $1
}

#create clone blkdev by bdsrc
function CLONEBLK {
#use csblkdev function,by send $1=bid $2=clone/snapshot
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
    csblkdev ${bid} clone
done
}
function SNAPSHOTBLK {
#use csblkdev function,by send $1=bid $2=clone/snapshot
for bid in `cat ${cpath}/conf/.tmp/bdsrc|awk '{print $1}'`
do
    csblkdev ${bid} snapshot
done
}
function CLONEBLK2 {
#use csblkdev function,by send $1=bid $2=clone/snapshot
for bid in `cat ${cpath}/conf/.tmp/bdsnapshot|awk '{print $1}'`
do
    csblkdev ${bid} clone
done

}

#cloned blkdev second w/r
function clonewr2 {
echo -e "\033[33m******clone blkdev testing 2******\033[0m"
#$1 bd${1}   $2 --> tmparg${2}
REMOVEFILE clone;
sleep 2
WRITEFILE clone clone
READFILE clone clone
}
#删除块设备
function DELETECLONE {
deletedev clone
rm -rf ${cpath}/conf/.tmp/bdclone
}
function DELETESNAPSHOT {
deletedev snapshot
rm -rf ${cpath}/conf/.tmp/bdsnapshot
}

function DELETESRC {
deletedev src
rm -rf ${cpath}/conf/.tmp/bdsrc
}
function DELETEBLK {
DELETESRC;
DELETECLONE;
DELETESNAPSHOT;
#${cpath}/conf/.tmp/*blk* ${cpath}/conf/.tmp/tmparg
}
#inita1
case $1 in
	create)
		inita1
		CREATE;;
	map)
		inita1
		MAP src;;
	startmount)
		inita1
		STARTMOUNT;;
	writefile)
		inita1
		WRITEFILE src;;
	readfile)
		inita1
		READFILE src;;
	removefile)
		inita1
		REMOVEFILE src;;
	
	startumount)
		inita1
		STARTUMOUNT src;;
	unmap)
		inita1
		UNMAP src;;
	delfdisk)
		inita1
		delfdiskf;;
	fdisk)
		inita1
		fdiskf;;
	
	delblk)
		inita1
		DELETESRC;;
	delclone)
		inita1
		DELETECLONE;;
	delsnapshot)
		inita1
		DELETESNAPSHOT;;
	scltmap)
		inita1
		SHOWCLIENTMAP
		;;
	expand)
		inita1
		EXPANDBLKDEV;;
	resize)
		inita1
		resizef;;
	clone)
		inita1
		CLONEBLK;;
	clonemap)
		inita1
		MAP clone;;
	cloneumount)
		inita1
		STARTUMOUNT clone;;
	clones)
		inita1	
		CLONEBLK2;;
	clonemount)
		inita1
		MOUNTSC clone;;
	cloneunmap)
		inita1
		UNMAP clone;;
	cloneread)
		inita1
		READFILE clone;;
	clonew2)
		inita1
		clonewr2;;
	snapread)
		inita1
		READFILE snapshot;;
	snapmap)
		inita1
		MAP snapshot;;
	snapunmap)
		inita1
		UNMAP snapshot;;
	snapmount)
		inita1
		MOUNTSC snapshot;;
	snapumount)
		inita1
		STARTUMOUNT snapshot;;
	snapshot)
		inita1
		SNAPSHOTBLK;;
	delall)
		inita1
		STARTUMOUNT clone >/dev/null 2>&1
		STARTUMOUNT src >/dev/null 2>&1
		STARTUMOUNT snapshot >/dev/null 2>&1
		STARTUMOUNT clone >/dev/null 2>&1
		STARTUMOUNT src >/dev/null 2>&1
		STARTUMOUNT snapshot >/dev/null 2>&1
                
		UNMAP src;
                UNMAP snapshot;
                UNMAP clone;
                DELETEBLK;;

	testsrc)
		inita1
		CREATE;
		MAP src;
		SHOWCLIENTMAP;
		STARTMOUNT;
		WRITEFILE src;
		READFILE src;
		EXPANDBLKDEV;
		REMOVEFILE src;
		STARTUMOUNT src;
		UNMAP src;
		DELETESRC;
		;;
	testclone)
		inita1
		#src blk
		CREATE;
                MAP src;
                STARTMOUNT;
                WRITEFILE src;
                READFILE src;
		STARTUMOUNT src;
                UNMAP src;
		#clone
		CLONEBLK;
		MAP clone;
		SHOWCLIENTMAP;
		MOUNTSC clone
		READFILE clone;
		STARTUMOUNT clone
		
		UNMAP clone;
		DELETECLONE;;
	testsnap)
		inita1
                #src blk
                CREATE;
                MAP src;
                STARTMOUNT;
                WRITEFILE src;
                READFILE src;
		STARTUMOUNT src;
                UNMAP src;
		#snap
		SNAPSHOTBLK;
		MAP snapshot;
		SHOWCLIENTMAP;
		MOUNTSC snapshot;
		READFILE snapshot;
		STARTUMOUNT snapshot;
		UNMAP snapshot;
		DELETESNAPSHOT;;
	testallwr)
		inita1
                CREATE;
                MAP src; 
                STARTMOUNT;
                WRITEFILE src;
                READFILE src;
                EXPANDBLKDEV;
		
		#clone
                CLONEBLK;
                MAP clone;
                STARTUMOUNT src;
		UNMAP src;
		MOUNTSC clone
                READFILE clone;
		clonewr2;
		STARTUMOUNT clone;		
		UNMAP clone;
		#snap
		SNAPSHOTBLK;
		MAP snapshot;
                MOUNTSC snapshot;
                READFILE snapshot;
		#umount  unmap delete
		SHOWCLIENTMAP;
                STARTUMOUNT snapshot;
                UNMAP snapshot;
               # DELETEBLK;
		;;
	 testallread)
                inita1
               # CREATE;
                MAP src;
                STARTMOUNT;
                READFILE src;
		STARTUMOUNT src;
		UNMAP src;
                #clone
                MAP clone;
                MOUNTSC clone;
		READFILE clone clone;
		STARTUMOUNT clone;
		UNMAP clone;
                #snap
                MAP snapshot;
                MOUNTSC snapshot;
                READFILE snapshot;
                #umount  unmap delete
                SHOWCLIENTMAP;
		STARTUMOUNT snapshot;
                UNMAP snapshot;
		;;
	testall)
		sh $0 testallwr
		wait
		DELETEBLK	
		;;	
	*)
		echo	"Usage:$0 testallwr|testallread|delall|testall"
		exit 1
esac
