---
title: nginx信号管理
date: 2022-06-29 21:17:17
categories: Linux
tags: [Linux , nginx]
---

# 概述
本文笔者主要介绍 nginx 信号管理方面的知识及实践操作，内容包括 nginx 信号管理体系，nginx 信号管理的常见操作，通过具体案例来分析，如 nginx 的 reload，热升级以及日志切割。

# nginx 命令行管理
nginx 的管理可以通过两种方式实现。一种是通过命令行，下面是 nginx 常用的操作命令，

```bash
root@sh192-168-1-71:~# nginx -h
nginx version: nginx/1.10.3 (Ubuntu)
Usage: nginx [-?hvVtTq] [-s signal] [-c filename] [-p prefix] [-g directives]

Options:
  -?,-h         : this help
  -v            : show version and exit
  -V            : show version and configure options then exit
  -t            : test configuration and exit
  -T            : test configuration, dump it and exit
  -q            : suppress non-error messages during configuration testing
  -s signal     : send signal to a master process: stop, quit, reopen, reload
  -p prefix     : set prefix path (default: /usr/share/nginx/)
  -c filename   : set configuration file (default: /etc/nginx/nginx.conf)
  -g directives : set global directives out of configuration file
```

另一种管理方式就是我们要介绍的`信号`。

# nginx 信号管理
nginx 的信号管理命令为：
```bash
kill -参数 nginx进程号
# 例子
kill -HUP 54321
kill -HUP $(cat /usr/local/nginx/logs/nginx.pid)
```
nginx 可用的信号如下，具体可以参考官网 [nginx.com](https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/) 。

- master process 可以接收的信号

| TERM, INT | Quick shutdown（优雅关闭进程，等请求结束后再关闭） |
| --- | --- |
| QUIT | Graceful shutdown（强制关闭进程） |
| KILL | Halts a stubborn process |
| HUP | Configuration reload, Start the new worker processes with a new configuration, Gracefully shutdown the old worker processes（改变配置后，平滑重新载入配置文件） |
| USR1 | Reopen the log files（开启新的日志文件，可以在日志切割时使用） |
| USR2 | Upgrade Executable on the fly（平滑升级） |
| WINCH | Gracefully shutdown the worker processes（优雅关闭旧的进程） |

- worker process 可以接收的信号

| TERM, INT | Quick shutdown |
| --- | --- |
| QUIT | Graceful shutdown |
| USR1 | Reopen the log files |

信号与命令行参数的映射关系如下：

| 参数 | 对应信号 |
| --- | --- |
| reload | HUP |
| reopen | USR1 |
| stop | TERM |
| quit | QUIT |

下面来分析下几个常见操作的流程。
# nginx reload(优雅重新加载配置)
```bash
# 使用命令行
nginx -s reload
# 使用信号
kill -HUP nginx进程号
```
当我们发送如上信号时，nginx 就会进行重新加载配置操作，具体的内部执行流程如下。
## nginx reload 流程

- 向 master 进程发送 HUP 信号（reload 命令）
- master 进程校验配置文件语法是否正确
- master 进程打开新的监听端口
- master 进程用新配置启动新的 worker 子进程
- master 进程向老的 worker 子进程发送QUIT 信号
- 老的 worker 子进程关闭监听句柄，处理完当前连接后结束进程
## nginx reload 实践
reload 前，nginx 进程号如下：
```bash
root@sh192-168-1-71:~# ps aux|grep nginx
root      7491  0.0  0.0  14228   948 pts/0    S+   00:29   0:00 grep --color=auto nginx
root     13253  0.0  0.0 124264  3004 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data 13254  0.0  0.0 125436  8544 ?        S    Jun12   3:35 nginx: worker process
www-data 13255  0.0  0.0 125428  8380 ?        S    Jun12   3:25 nginx: worker process
www-data 13256  0.0  0.0 125356  8436 ?        S    Jun12   3:39 nginx: worker process
www-data 13257  0.0  0.0 125428  8456 ?        S    Jun12   3:27 nginx: worker process
www-data 13258  0.0  0.0 125428  8468 ?        S    Jun12   3:19 nginx: worker process
www-data 13260  0.0  0.0 125348  8380 ?        S    Jun12   3:17 nginx: worker process
www-data 13261  0.0  0.0 125468  8504 ?        S    Jun12   3:27 nginx: worker process
www-data 13263  0.0  0.0 124844  7928 ?        S    Jun12   3:20 nginx: worker process
```
修改配置执行 reload 之后，nginx 进程号发生变化，如下：
```bash
root@sh192-168-1-71:~# /etc/init.d/nginx reload
[ ok ] Reloading nginx configuration (via systemctl): nginx.service.
root@sh192-168-1-71:~# 
root@sh192-168-1-71:~# ps aux|grep nginx
www-data  7701  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7702  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7704  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7705  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7706  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7707  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7709  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7710  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
root      7737  0.0  0.0  14228   860 pts/0    S+   00:30   0:00 grep --color=auto nginx
root     13253  0.0  0.0 125828  8540 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
```
# nginx 热升级
## nginx 热升级流程

- 将旧的 nginx 二进制文件换成新的 nginx 二进制文件（注意备份）
- 向 master 进程发送 USR2 信号
- master 进程修改 pid 文件名，加后缀 .oldbin
- master 进程用新 nginx 二进制文件启动新的 master 进程
- 向老 master 进程发送 QUIT 信号，关闭老 master 进程
- 回滚：向老 master 进程发送 HUP，向新 master 进程发送 QUIT
## nginx 热升级实践
先将原来的 nginx 二进制文件备份一下
```bash
root@sh192-168-1-71:~# ls -alh /usr/sbin/nginx
-rwxr-xr-x 1 root root 1.2M Jan 11  2020 /usr/sbin/nginx

root@sh192-168-1-71:~# cp /usr/sbin/nginx /usr/sbin/nginx.bak

root@sh192-168-1-71:~# ls -alh /usr/sbin/nginx*
-rwxr-xr-x 1 root root 1.2M Jan 11  2020 /usr/sbin/nginx
-rwxr-xr-x 1 root root 1.2M Jun 29 00:32 /usr/sbin/nginx.bak
```
将原来的 nginx 二进制文件替换成新的二进制文件
```bash
root@sh192-168-1-71:~# cp /tmp/nginx.new /usr/sbin/nginx
```
向 master 进程发送 USR2 信号
```bash
root@sh192-168-1-71:~# ps aux|grep nginx
www-data  7701  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7702  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7704  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7705  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7706  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7707  0.0  0.0 125828  5896 ?        S    00:30   0:00 nginx: worker process
www-data  7709  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7710  0.0  0.0 125828  5900 ?        S    00:30   0:00 nginx: worker process
root      8332  0.0  0.0  14228   916 pts/0    S+   00:33   0:00 grep --color=auto nginx
root     13253  0.0  0.0 125828  8540 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;

root@sh192-168-1-71:~# kill -USR2 13253
```
此时再看 nginx 进程列表，会发现 nginx 进程数量多了一倍。新的 master 进程是基于新的 nginx 二进制文件运行的，其下也创建了新的 worker 进程。
```bash
root@sh192-168-1-71:~# ps aux|grep nginx
www-data  7701  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7702  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7704  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7705  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7706  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7707  0.0  0.0 125828  5896 ?        S    00:30   0:00 nginx: worker process
www-data  7709  0.0  0.0 125828  4904 ?        S    00:30   0:00 nginx: worker process
www-data  7710  0.0  0.0 125828  5900 ?        S    00:30   0:00 nginx: worker process
root     13253  0.0  0.0 125828  8540 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data  8884  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8885  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8886  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8888  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8889  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8890  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8892  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8893  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
root      8921  0.0  0.0  14228   900 pts/0    S+   00:36   0:00 grep --color=auto nginx
root     13253  0.0  0.0 125828  8544 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
```
接下来，向老 master 进程发送 QUIT 信号，关闭老 master。随后，我们会发现老 master 和 worker 进程已经关闭，只剩余新的 master 和 worker 进程。
```bash
root@sh192-168-1-71:~# kill -QUIT 13253

root@sh192-168-1-71:~# ps aux|grep nginx
www-data  8884  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8885  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8886  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8888  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8889  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8890  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8892  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8893  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
root      8921  0.0  0.0  14228   900 pts/0    S+   00:36   0:00 grep --color=auto nginx
root     13253  0.0  0.0 125828  8544 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
```
至此，我们就完成了 nginx 热升级过程。
# nginx 日志切割
```bash
# 使用命令行
nginx -s reopen
# 使用信号
kill -USR1 nginx进程号
```
## nginx 日志切割实践
初始的日志文件如下
```bash
root@sh192-168-1-71:~# ls -alh /var/log/nginx/access.log
-rw-r----- 1 www-data adm 8.1K Jun 28 11:46 /var/log/nginx/access.log
```
接着我们讲 access 日志重命名
```bash
root@sh192-168-1-71:~# mv /var/log/nginx/access.log /var/log/nginx/access.log.1

root@sh192-168-1-71:~# ls -alh /var/log/nginx/* |grep 'access.log'
-rw-r----- 1 www-data adm  8.1K Jun 28 11:46 /var/log/nginx/access.log.1
```
使用日志 reopen，即发送 USR1 信号
```bash
root@sh192-168-1-71:~# ps aux|grep nginx
www-data  8884  0.0  0.0 125828  5900 ?        S    00:36   0:00 nginx: worker process
www-data  8885  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8886  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8888  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8889  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8890  0.1  0.0 125828  5900 ?        S    00:36   0:00 nginx: worker process
www-data  8892  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
www-data  8893  0.0  0.0 125828  4904 ?        S    00:36   0:00 nginx: worker process
root      9873  0.0  0.0  14228  1016 pts/0    S+   00:41   0:00 grep --color=auto nginx
root     13253  0.0  0.0 125828  8544 ?        Ss   Jun12   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
root@sh192-168-1-71:~# 
root@sh192-168-1-71:~# kill -USR1 13253
```
此时会发现有新的 access.log 文件生成
```bash
root@sh192-168-1-71:~# ls -alh /var/log/nginx/* |grep 'access.log'
-rw-r--r-- 1 www-data root    0 Jun 29 00:41 /var/log/nginx/access.log
-rw-r----- 1 www-data adm  8.1K Jun 28 11:46 /var/log/nginx/access.log.1
```

至此，我们已经了解了 nginx 常见的信号，以及这些信号的实际作用。


