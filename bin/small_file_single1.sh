#!/bin/bash
cpath1=`dirname $0`
cpath=`cd "${cpath1}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common
#echo ${cpath}
#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
writefile="python ${cpath}/lib/wrfile.py"
filesh=small_file_single1.sh
smfselog=${testdir}/log/smallf_singleerror.log
smfslog=${testdir}/log/smfslog1.log
writepath=${testdir}/smf_single1
pwdp=`pwd`
function init {
mkdir -p ${testdir}/log
for i in $(seq 1 $fileNum_sd)
do
rm -rf $writepath/smf_single*_${i}.txt &
done
wait
rm -rf $writepath  	#删除目录
rm -rf $smfselog $smfslog #删除旧日志
dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}


function run {
cd $testdir
valw=`$writefile smf_single1  1 1000 100 100 ${fileNum_sd1} 2>&1`
flag=$?
checkok $flag "write_$valw"

if [[ "$valw" =~ "error" ]]||[ "$flag" != "0" ];then
	echo -e "$filesh:$numt  write  failed "
        echo -e "$filesh:$numt  write \n $valw" >> $smfselog
else 
	echo -e "$filesh:$numt write  pass "
        echo -e "$filesh:$numt write \n $valw" >> $smfslog

fi
}

function check {
cd $testdir
valr=`$writefile smf_single1 2 1000 100 100 ${fileNum_sd1} 2>&1`
flag=$?
checkok $flag "read_$valr"

if [[ "$valr" =~ "error" ]]||[ "$flag" != "0" ];then
        echo -e "$filesh:$numt  read  failed "
        echo -e "$filesh:$numt  read \n $valr" >> $smfselog
else
        echo -e "$filesh:$numt read  pass "
        echo -e "$filesh:$numt read \n $valr" >> $smfslog

fi
}
menu $1
#echo $pwdp
cd $pwdp

