#!/usr/bin/python
#-*- coding:utf-8 -*-
import multiprocessing
import os,sys,subprocess
import time

hname=subprocess.Popen("hostname",shell=True,stdout=subprocess.PIPE)
print ''.join(hname.stdout.readlines())

