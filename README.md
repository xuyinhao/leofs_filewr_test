# leofs_filewr_test
leotest add py multiPoolTask
#背景
需要测试分布式文件系统
#任务
每个客户端节点需要同时进行文件读写测试
其中包含了不同大小，不同冗余度设置，以及可控的文件测试类型，大小等参数
#目录介绍
├── bin    //一些公共的方法以及需要调用的脚本
│   ├── blkcommon
│   ├── blktest.sh
│   ├── common
│   ├── Devices.info
│ 	... *.sh  			//各个用例所需的脚本执行以及简单日志分析
├── conf        //配置信息  
│   ├── default.conf	 //必须配置，设置文件读写位置以及哪些客户端节点
│   ├── leofslayout.conf       //冗余度的设置
│   └── testcase.conf  			//测试项的选择
├── lib		//测试工具类
│   ├── check.jar
│   ├── create.jar
│   ├── FileTest.jar
│   ├── filewr.py
│   ├── test_multhr_meta7
│   └── wrfile.py
├── log			//日志存放
├── README.md
├── sbin
│   ├── blktest.sh			//块设备的测试
│   ├── multiPoolTask.py		//py multiPoolTask进程池 控制每个节点同时进行的任务数;multasknum
│   └── testwr.sh            //文件读写测试
└── while.sh	// overnight测试

#使用
* 1	需要先对客户端节点进行 SSH免密设置，各个节点需要安装JAVA,PYTHON环境
* 2	设置相关的conf设置项
* 3	读写测试，并查看测试日志

 >存在的问题:函数调用以及位置 不是很完善;测试用例bin部分略臃肿

