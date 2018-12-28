#!/bin/bash
cpath=`dirname $0`
cpath=`cd "${cpath}";cd "..";pwd`
. ${cpath}/conf/default.conf
. ${cpath}/bin/common

#numt=$2
#testdir=`cat ${cpath}/conf/.tmptestdir${2}`
testdir=$2
testmul="${cpath}/lib/test_multhr_meta7"
filesh=test_multhr_meta.sh
mulelog=${testdir}/log/mulerror.log

function init {
mkdir -p ${testdir}/log
rm -rf ${testdir}/mul_dir*
rm -rf ${testdir}/log/test_multhr*
rm -rf ${mulelog}
dmesg -c > /dev/null
}
function remove_dir {
#if [ "$cmdcmd" = "remove" ];then
        rmdir ${testdir}/log > /dev/null 2>&1
        rmdir ${testdir} > /dev/null 2>&1
#fi
}
function run {
for i in $(seq 1 $run_times)
do
	muldir=${testdir}/mul_dir_${i}
	mkdir -p ${muldir}
	log=${testdir}/log/test_multhr_meta${i}.log
	$testmul ${muldir} 1 $mult_threadnum ${filenum_per_thread} 1 >> $log 2>&1
	mulwrcheck $? "error:1 for write" 1
	${testmul} ${muldir} 2 $mult_threadnum ${filenum_per_thread} 1 >> $log 2>&1
	mulwrcheck $? "error:2 for read" 2
	$testmul ${muldir} 4 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:4 for rename in same dir" 4
	$testmul ${muldir} 5 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:5 for rename in diff dir" 5 
	${testmul} ${muldir} 6 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:6 for link in same dir" 6
	$testmul ${muldir} 7 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:7 for link in diff dir" 7
	$testmul ${muldir} 8 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:8 for lstat all files" 8 
	$testmul ${muldir} 10 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:10 for phase1 rename" 10
	$testmul ${muldir} 9 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:9 for lstat after phase1 rename" 9
	$testmul ${muldir} 11 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:11 for phase2 rename" 11
	$testmul ${muldir} 8 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:8 for lstat all files" 8
	$testmul ${muldir} 3 $mult_threadnum ${filenum_per_thread} 1  >> $log 2>&1
	mulwrcheck $? "error:3 for remove" 3
done
}
function check {
for i in $(seq 1 $run_times)
do
    log=${testdir}/log/test_multhr_meta${i}.log
    val=`cat $log |grep error`
    val2=`cat $log |grep "No such"`
    val3=`cat $log|grep "failed"`    


     if [ "$val" != "" -o  "$val2" != "" -o "$val3" != "" ];then
      echo -e  "${filesh}${i}_${numt}:check  log  failed "  
      echo "$log failed" >> $mulelog
      echo "$val" "$val2" "$val3" >> $mulelog
    else 
      echo -e "${filesh}${i}_${numt}:check  log  pass "
    fi
 #  dmesg -c >> ${testdir}/log/test_multhr_dmesg.log
done
}

case $1 in
         "write"|"check"|"all")
	   init
           run
           check
         ;;
         "remove")
           init
         ;;
         *)
          echo "Argument1:write|check|remove|all"
         ;;
 esac

