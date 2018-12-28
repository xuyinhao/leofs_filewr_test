#!/usr/bin/python
#-*- coding:utf-8 -*-
##2018-xu
##argv1:任务操作cmd. argv2:当前机器被分配的.line数 . argv3 :脚本path
import multiprocessing
import os,sys,subprocess
import time

multasknum=2 	 #一台机器 同时执行的任务数 。池
exec_task_cmd=sys.argv[1]
cmd_linenum=sys.argv[2] #当前需要读取的line
cpaths=sys.argv[3]  #cpath 相对路径
#cmd_line2='line1'


def hostname():
    hname=subprocess.Popen("hostname",shell=True,stdout=subprocess.PIPE)
    return ''.join(hname.stdout.readlines())
def bash_script(bash):
    taskbash=bash.split(' ')
    cmdexec=exec_task_cmd
    print hostname(),time.ctime()
    return_c=subprocess.Popen("sh " +cpaths +"/bin/"+taskbash[0] + ' '+cmdexec+' '+taskbash[1], shell=True,stdout=subprocess.PIPE)
    print('sh '+cpaths +"/bin/"+taskbash[0] + ' '+ cmdexec+' '+ taskbash[1])
    print(''.join(return_c.stdout.readlines()))
   # print(arg1)

def testcase_obo():
    try:
    	with open(cmd_linenum,'r') as f:
            lines = f.readlines()
            thr = multasknum if len(lines)> multasknum else len(lines)
	    try:
            	p = multiprocessing.Pool(thr)
	    	for i in lines:
#       threading.Thread(target=check_file,args=(lines[i::thr],),name="thread-"+str(i)).start()
                    p.apply_async(bash_script,args=(i,))
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
