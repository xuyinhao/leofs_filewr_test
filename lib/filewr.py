#!/usr/bin/python
import sys
import thread
import threading
import time
import os
import subprocess

class myThread(threading.Thread):
	def __init__(self,threadname):
		threading.Thread.__init__(self)
		self.name = threadname

	def run(self):
		opFile(self.name)

def getStr(cycle,length,prefix):
	str = ''
	chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789'
	lens = len(chars) - 1
	str = chars[(cycle+prefix)%lens] * length
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

def opFile(thrname):
	file = sys.argv[1]
	optype = sys.argv[2]
	fsize = unit(sys.argv[3])
	bsize = unit(sys.argv[4])
	bskip = long(sys.argv[6])
	eskip = long(sys.argv[7])
	prefix = 0
	if len(sys.argv) == 9:
		prefix = long(sys.argv[8])
	wbuffer = ''
	cycle = 0
	dosize = 0
	rsize = 0
	opfile = file + '_' + thrname + '.txt'
	return_code=subprocess.Popen("/LeoCluster/bin/leofs_getgrpinfo "+opfile+" 0", shell=True,stdout=subprocess.PIPE)
        re=return_code.stdout.readlines()
        print(''.join(re))

	begintime = time.time()
	try:
		if optype == '1':
			if not os.path.exists(opfile):
				os.mknod(opfile)
			f = open(opfile ,'r+')
			print 'begin to write ' + opfile + ' at ' + time.ctime(begintime) + "\n",
		else:
			f = open(opfile ,'r')
			print 'begin to read ' + opfile + ' at ' + time.ctime(begintime) + ' skip data: ' + str(bskip) + '-' + str(eskip) + "\n",
	except:
		print "open %s file error!\n" % opfile,
		exit(1)
	while fsize > dosize:
		if optype == '1':
			if (fsize - dosize) > bsize:
				wbuffer = getStr(cycle+long(thrname),bsize,prefix)
			else:
				wbuffer = getStr(cycle+long(thrname),fsize - dosize,prefix)
			try:
				f.write(wbuffer)
			#	f.flush()
			except IOError:
				print "%s ioerror.\n" % opfile,
				exit(1)
			except Exception as e:
				print("%s error as :%s" %(opfile,e))
		else:
			if os.path.getsize(opfile) != fsize:
				print "%s size error:%d,expect:%d\n" % (opfile, os.path.getsize(opfile), fsize),
				exit(1)
			if (fsize - dosize) > bsize:
                                wbuffer = getStr(cycle+long(thrname),bsize,prefix)
				rsize = bsize
                        else:
                                wbuffer = getStr(cycle+long(thrname),fsize - dosize,prefix)
				rsize = fsize - dosize
			try:
				rbuffer = f.read(rsize)
				while len(rbuffer) < rsize:
					print "%s read length error:read:%d expect: %d at %d\n" % (opfile, len(rbuffer), rsize, f.tell()),
					rbuffer = rbuffer+f.read(rsize-len(rbuffer))
					
			except IOError:
                                print "%s ioerror.\n" % opfile,
				exit(1)
			if wbuffer != rbuffer:
				if not (((cycle * bsize) < bskip and ((cycle + 1) * bsize >= bskip)) or ((cycle * bsize) < eskip and ((cycle + 1) * bsize >= eskip)) or ((cycle * bsize) < bskip and ((cycle + 1) * bsize >= eskip)) or ((cycle * bsize) > bskip and ((cycle + 1) * bsize <= eskip))):
					return_code=subprocess.Popen("/LeoCluster/bin/leofs_getgrpinfo "+opfile+" 0", shell=True,stdout=subprocess.PIPE)
					re=return_code.stdout.readlines()
					print(''.join(re))	
					print "%s content error at %s" % (opfile,str(cycle * bsize))
					print "wbuffer:" + wbuffer
					print "rbuffer:" + rbuffer
					exit(1)
		cycle += 1
		dosize += len(wbuffer)
	endtime = time.time()
	speed = fsize/(endtime-begintime)/1024/1024
	print 'finished op ' + opfile + ' at ' + time.ctime(endtime) + ' speed: ' + str(speed) + 'MB/s'
	f.close

if __name__ == "__main__":
	if len(sys.argv) != 8 and len(sys.argv) != 9:
		print "Usage:filename optype(1:write, 2:read) filesize blocksize thread_num bskip eskip [prefix]"
		exit(1)
	thread = int(sys.argv[5])
	threads = []
	try:
		for i in range(0,thread):
			threadname = str(i)
			threads.append(myThread(threadname))
		for t in threads:
			t.start()
		for t in threads:
			t.join()
	except:
		print 'error: thread error!'
	print 'test finish!'

