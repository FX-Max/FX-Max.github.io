---
title: MySQL主从复制-Could not initialize master info structure

date: 2016-06-18 14:18:07
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2020/bg/bg0221.jpg'
categories: mysql
tags: [mysql , 运维]
---

 最近开始摸索 MySQL 主从复制，在测试环境进行了相关测试，也遇到了不少的坑。如在从库设置同步的时候，报如下错误：

> ERROR 1201 (HY000): Could not initialize master info structure .

出现这个错误的原因是因为从库之前已经做过主从复制,所以需要先停止从库，再进行从库同步设置。

<!-- more -->

具体的解决方法如下：

```
mysql> change master to master_host='192.168.1.51', master_user='replslave', master_password='replslave', master_log_file='mysql-bin-000002',master_log_pos=168;   
ERROR 1201 (HY000): Could not initialize master info structure; more error messa  
ges can be found in the MySQL error log 
mysql> stop slave;
Query OK, 0 rows affected, 1 warning (0.00 sec) 
mysql> reset slave;  
Query OK, 0 rows affected (0.00 sec) 
mysql> change master to master_host='192.168.1.51', master_user='replslave', master_password='replslave', master_log_file='mysql-bin-000002',master_log_pos=168; 
Query OK, 0 rows affected (0.11 sec)  
```

---

Happy Coding.

