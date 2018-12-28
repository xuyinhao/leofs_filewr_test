#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd ..;pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
createcmd="java -jar ${cpath}/lib/create.jar"
checkcmd="java -jar ${cpath}/lib/check.jar"
filesh=small_file_mul.sh
smfmelog=${testdir}/log/smallfilemulerror.log
smfmlog=${testdir}/log/smfmlog.log

function init {
mkdir -p ${testdir}/log
for i in $(seq 0 $((10#$dirNum-1)))
do
   rm -rf ${testdir}/smf_mul/dir$i &
done
wait
rm -rf ${testdir}/smf_mul
rm -rf $smfmelog $smfmlog
dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}

function run {
#create file
valw=`$createcmd ${testdir}/smf_mul dir $dirNum file $fileNum 1000 100 30 $depth 0 2>&1` 

checkok $? "create__$valw"

if [[ "$valw" =~ "speed:" ]];then
	echo -e "$filesh:$numt :dir:$dirNum file:$fileNum depth:$depth  create pass "
	echo -e "$filesh:$numt create \n $valw" >> $smfmlog
else 
	echo -e "$filesh:$numt dir:$dirNum file:$fileNum depth:$depth  create failed"
        echo -e "$filesh:$numt  create \n $valw" >> $smfmelog
 #       exit
fi
}
#check file
function check {
valr=`$checkcmd ${testdir}/smf_mul dir $dirNum file $fileNum 1000 100 30 $depth 0 2>&1`
checkok $? "check__$valr"
echo $valr >> $smfmlog
dataerr=`wordcount $smfmlog  dataerr`
noexist=`wordcount $smfmlog noexist`
lenerr=`wordcount $smfmlog  lenerr`

if [ "$dataerr" != "" -o  "$noexist" != "" -o "$lenerr" != "" ];then
        echo -e "$filesh:$numt dataerr:$dataerr noexist:$noexist lenerr:$lenerr  faild"
       echo -e "$filesh:$numt check \n $valr" >> $smfmelog
else
       echo -e "$filesh:$numt :dir:$dirNum file:$fileNum depth:$depth check  pass "
       echo -e "$filesh:$numt check  \n  $valr" >> $smfmlog
fi
#dmesg -c >> ${testdir}/log/small_file_muldmesg.log
}
menu $1

