#!/usr/bin/python
#-*- coding:utf-8 -*-
##2018-xu
# 被 sbin/start_wr.sh脚本所调用
##argv1:任务操作cmd. argv2:当前机器被分配的.line数 . argv3 :脚本path
import multiprocessing
import os,sys,subprocess
import time

multasknum=2					#一台机器 同时执行的任务数 。池
exec_task_cmd=sys.argv[1]		#write,check,remove,all
cmd_linenum=sys.argv[2]			#当前需要读取的lineNum,获取本机任务
cpaths=sys.argv[3]				#cpath：脚本所在绝对路径
#cmd_line2='line1'


def bash_cmd(args):
	cmdRet=subprocess.Popen(args,shell=True,stdout=subprocess.PIPE)
	return ''.join(cmdRet.stdout.readlines())

def hostname():
    return bash_cmd("hostname")

def exec_wr_bash_script(parm):
    taskbash=parm.split(' ')
    cmdexec=exec_task_cmd
    print(hostname(),sys.stderr)
    print(time.ctime())
    return_c=subprocess.Popen("sh " +cpaths +"/bin/"+taskbash[0] + ' '+cmdexec+' '+taskbash[1] +' ' + taskbash[2], shell=True,stdout=subprocess.PIPE)
    #print('sh '+cpaths +"/bin/"+taskbash[0] + ' '+ cmdexec+' '+ taskbash[1]+ ' ' + taskbash[2])
    print(''.join(return_c.stdout.readlines()))
   # print(arg1)

def testcase_obo():
    try:
    	with open(cmd_linenum,'r') as f:
            lines = f.readlines()
            thr = multasknum if len(lines)> multasknum else len(lines)
	    try:
            	p = multiprocessing.Pool(thr)
	    	for parms in lines:
#       threading.Thread(target=check_file,args=(lines[i::thr],),name="thread-"+str(i)).start()
                    p.apply_async(exec_wr_bash_script,args=(parms,))
            	p.close()
            	p.join()
	    except KeyboardInterrupt:
            	print "Caught KeyboardInterrupt, terminating workers!"
            	p.terminate()
            	p.join()
    except Exception as e:
	print "has some error",e
if __name__ == '__main__':
    cmd_cmd1=sys.argv[1]
    cmd_linenum=sys.argv[2] #当前需要读取的line
    cpaths=sys.argv[3]  #cpath 相对路径
    testcase_obo()
