#!/bin/sh
#\
exec expect -- "$0" "$@"

set port 22
set user "root"
set timeout 120
set password "111111"
set host ""
set mode ""
set command ""
set src ""
set dst ""


proc help {} {
   global argv0
    send_user "usage: $argv0\n"
    send_user "    -i <ip>           Host or IP\n"
    send_user "    -P <port>         Port. Default = 22\n"
    send_user "    -u <user>         UserName. Default = root\n"
    send_user "    -p <password>     Password. Default = 111111 \n"
    send_user "    -t <timeout>      Timeout. Default = 120\n"
    send_user "    -m <mode>         Mode. include: ssh-cmd, scp-out, scp-in\n"
    send_user "			-m ssh-cmd -c 'ifconfig'\n"
    send_user "			-m scp-out -s '/var/log/messages -d /tmp/'\n"
    send_user "			-m scp-in -s '/var/log/messages -d /tmp/'\n"
    send_user "    -c <command>      Ssh Command. ssh-cmd mode must\n"
    send_user "    -s <src>          Scp Source File. ssh-out,scp-in mode must \n"
    send_user "    -d <dst>          Scp Destination File. ssh-out,scp-in mode must\n"
    send_user "    -h                Help\n"
    send_user "Sample:\n"
    send_user "$argv0 -i 13.10.12.27 -p pass -t 5 -m ssh-cmd -c ifconfig\n"
    send_user "$argv0 -i 13.10.12.27 -p pass -m scp-out -s /etc/passwd -d /tmp/passwd\n"

}

proc errlog {errmsg h code} {
	global host
	send_user "Error : $errmsg on $host (${code}) \n"
	if {[string compare "$h" "yes"] == 0} {
		help
	}
	exit $code
}
# 参数个数不能为0
if {[llength $argv] == 0} {
	errlog "arg 0 " "yes" "1"
}

#参数解析
#可以通过[lindex $argv n]来获取第n个参数。
#[lrange $argv start end]来获取start到end的参数。
while {[llength $argv]>0} {
    set flag [lindex $argv 0]
    switch -- $flag "-i" {
        set host [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-P" {
        set port [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-u" {
        set user [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-p" {
        set password [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-t" {
        set timeout [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-m" {
        set mode [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-c" {
        set command [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-s" {
        set src [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-d" {
        set dst [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-v" {
  send_user "Ver: 1.0.0.0\n"
        exit 0
    } "-h" {
        help
        exit 0
    } default {
	send_user "******************\n"
        break
    }
}

#主机名或者ip为空
if { "$host" == ""} {
	errlog "host is null" "yes" "1"
}

#执行命令
if {[string compare "$mode" "ssh-cmd"] == 0} {

	if {"$command" == ""} {
	errlog "command is null" "yes" "1"	
	}
	spawn ssh -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -t -p $port $user@$host "$command"
} elseif {[string compare "$mode" "scp-out"] == 0} {
	if {"$src" == "" || $dst == ""} {
	errlog "src or dst is null " "yes" "1"
	}
	spawn scp -r -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -P $port $src $user@$host:$dst 
} elseif {[string compare "$mode" "scp-in"] == 0} {
  if {"$src" == "" || $dst == ""} {
        errlog "src or dst is null " "yes" "1"
        }
        spawn scp -r -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -P $port $user@$host:$src $dst
} elseif {[string compare "$mode" "cat-ssh"] == 0} { 
if {"$src" == "" || $dst == ""} {
        errlog "src or dst is null " "yes" "1"
        }
	spawn /bin/sh -c "cat $src | ssh -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -t -p $port $user@$host 'cat > $dst'"
} else {
	errlog "mode($mode) invalid" "yes" "1"	
}

#命令执行结果
expect {
 #.regexp模式以-re开头
 -nocase -re "please try again" {
	errlog "Bad password/username , or a"  "no" "128"
	}
 -nocase -re "password:" {
	send "$password\r"
	exp_continue
	}
	timeout {
	errlog "Time out" "no" "129"
	}
}


#获取命令执行结果
#wait命令的返回值是一个"%d %s 0 %d"格式的字符串,第0个值是pid,第1个是spawn_id(不知道它具体带表了什么),第2个应当是代表脚本是否正常完成,第3个是子进程的返回值.
catch wait result
set ret [lindex $result 3]
if { $ret != 0 } {
    #如有远端没有scp命令的话,scp会失败的,此时需要使用cat+ssh的方法拷贝数据
    #暂不考虑从远端拷贝数据至本地,且远端无scp的场景
    if {$ret == 1 && [string compare "$mode" "scp-out"] == 0} {
        spawn /bin/sh -c "cat $src | ssh -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -t -p $port $user@$host 'cat > $dst'"
        #命令执行结果
        expect {
            -nocase -re "please try again" {
                errlog "Bad Password/UserName, Or Account locked" "no" "128"
            }
            -nocase -re "password" {
                send "$password\r"
                exp_continue
            }
            timeout {
                                            errlog "Executing timeout" "no" "129"
            }
        }

        #获取命令执行结果
        catch wait result
        set ret [lindex $result 3]
        if { $ret == 0 } {
            exit 0
        }
    }
    errlog "Execute failed" "no" "$ret"
}
exit $ret
