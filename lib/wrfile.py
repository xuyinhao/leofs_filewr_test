#!/usr/bin/python
#-*-coding:utf8-*-
#small file add cycle
import sys
import thread
import threading
import time
import os

#直接从threading.Thread继承，然后重写 __init__方法
class myThread(threading.Thread): #继承父类threading.Thread
	def __init__(self,threadname,c):
		threading.Thread.__init__(self)  #
		self.name = threadname
		self.cyc = c
	def run(self):  #要执行的代码写在run函数里面 线程在创建后台直接运行run函数
		opFile(self.name,self.cyc)
def getStr(cycle,length):
	str = ''
	chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789'
	#lens = len(chars) - 1
	lens = len(chars)
	str = chars[cycle%lens] * length
	return str

def unit(lensize):
	if (lensize[len(lensize)-1] == 'k' or lensize[len(lensize)-1] == 'K') :
		aa=lensize[:-1]
		aa=long(aa)*1024
		return aa
	elif (lensize[len(lensize)-1] == 'm' or lensize[len(lensize)-1] == 'M') :
		aa=lensize[:-1]
		aa=long(aa)*1024*1024
		return aa
	elif (lensize[len(lensize)-1] == 'g' or lensize[len(lensize)-1] == 'G') :
		aa=lensize[:-1]
		aa=long(aa)*1024*1024*1024
		return aa
	elif (lensize[len(lensize)-1] == 't' or lensize[len(lensize)-1] == 'T') :
		aa=lensize[:-1]
		aa=long(aa)*1024*1024*1024*1024
		return aa
	else :
		aa=long(lensize)
		return aa

def opFile(thrname,cyc):
	file = sys.argv[1]
	optype = sys.argv[2]
	#fsize = long(sys.argv[3])
	fsize = long(unit(str(sys.argv[3])))
	#bsize = long(sys.argv[4])
	bsize = long(unit(str(sys.argv[4])))
	cycle = 0
	dosize = 0
	rsize = 0
	opfile = file + '_' + thrname+'_'+ str(cyc) + '.txt'
	begintime = time.time()
	try:
		#opfile="test/"+opfile
		if optype == '1':
			f = open(opfile ,'w')
			print 'begin to write ' + opfile + ' at ' + time.ctime(begintime)
		else:
			f = open(opfile ,'r')
			print 'begin to read ' + opfile + ' at ' + time.ctime(begintime)
	except:
		print "open file error!"
		sys.exit(1)
	while fsize > dosize:
		if optype == '1':
			if (fsize - dosize) > bsize:
				wbuffer = getStr(cycle+long(thrname),bsize)
			else:
				wbuffer = getStr(cycle+long(thrname),fsize - dosize)
			f.write(wbuffer)
			#os.fsync(f)
		else:
			if (fsize - dosize) > bsize:
				wbuffer = getStr(cycle+long(thrname),bsize)
				rsize = bsize
				rbuffer = f.read(rsize)
			else:
				wbuffer = getStr(cycle+long(thrname),fsize - dosize)
				rsize = fsize - dosize
				rbuffer = f.read()
			if wbuffer != rbuffer:
				print "content error at " + str(cycle * bsize)
				print "wbuffer:" + wbuffer
				print "rbuffer:" + rbuffer
				sys.exit(1)
		cycle += 1
		dosize += len(wbuffer)
	endtime = time.time()
	speed = fsize/(endtime-begintime)/1024/1024
	print 'finished op ' + opfile + ' at ' + time.ctime(endtime) + ' speed: ' + str(speed) + 'MB/s'
	f.close
def mkdir(filename):
	if os.path.exists(filename) :
		print '\033[31;1m dir %s existed \033[0m'%(filename)
		sys.exit(1)
	else :
		os.mkdir(filename)
		print 'create dir  %s success'%(filename)
		os.chdir(filename)

if __name__ == "__main__":
	if len(sys.argv) != 7:
		print "\033[31;1m Usage:filename optype(1:write, 2:read) filesize(k,m,g,t) blocksize(k,m,g,t) thread_num cycle\033[0m"
		sys.exit(1)
	if sys.argv[2] == '1' :
		mkdir(sys.argv[1])    
	else :
		try:
			os.chdir(sys.argv[1])
		except:
			print "\033[31;1m dir %s not existed \033[0m"%(sys.argv[1]) 
			sys.exit(1)
	
	cyc=int(sys.argv[6])
	for c in range(1,cyc+1):
		thread = int(sys.argv[5])
		threads = []
		try:
			for i in range(1,thread+1):
				threadname = str(i)
				threads.append(myThread(threadname,c))
			for t in threads:
				t.start()
			for t in threads:
				t.join()
		except:
			print 'error: thread error!'
		print 'test finish!'
