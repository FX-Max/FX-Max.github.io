---
title: MySQL-出现 MySQL server has gone away 原因和解决方法
date: 2020-12-08 22:53:27
cover: 'https://cdn.immaxfang.com/images/post/2020/bg/bg1228.jpg'
categories: MySQL
tags: [MySQL]
---

# 可能的原因
- MySQL 服务宕机
- MySQL 连接被主动 kill 掉
- MySQL 连接超时
- SQL 超长，超出 max_allowed_packet 限制

<!-- more -->

# 具体情况分析和处理

## MySQL 服务宕机
可能是异常情况，访问过程中数据库宕机或重启了，期间的数据库访问请求会出现错误。
此种情况可以查看对应时候的 MySQL 相关日志，或者查询 MySQL 运行时间。可通过运行时间和日志，判断该时间是否有服务中断。
```
mysql> show global status like 'uptime';
+---------------+----------+
| Variable_name | Value    |
+---------------+----------+
| Uptime        | 23948658 |
+---------------+----------+
```

## MySQL 连接被主动 kill 掉
部分系统会配置一些连接数过多等情况下，脚本主动 kill 掉相关数据库请求进程，或者可能 DBA 等处理问题时手动 kill 掉，此种情况下也会出现报错。
```
mysql> show global status like 'com_kill';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| Com_kill      | 100   |
+---------------+-------+
```

## MySQL 连接超时
MySQL 的连接开启后，很久没有发起新的查询请求，达到了 server 端的超时时间，被 server 端强制关闭连接。此时若该连接再次发起请求时，则会报错 MySQL server has gone away 。此种情况比较常见，一般一个执行时间很长的脚本，开启连接查询部分数据后，进行计算或者请求第三方，在进行数据写入，写入时超时。
可以通过如下命令查看当前 MySQL 的超时时间，
```
mysql> show global variables like 'wait_timeout';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| wait_timeout  | 28800 |
+---------------+-------+
```

可以通过如下命令临时修改超时时间，
```
mysql> set global wait_timeout = 60 * 60 * 8;
```
如要长期生效，则需要修改数据库配置文件，并重启 MySQL 服务。
```
wait_timeout = 28800
interactive_timeout = 28800
```

## SQL 超长，超出 max_allowed_packet 限制
MySQL 会限制 server 段接收的数据包的大小，有时候大的插入和更新发送的数据包大小超过 max_allowed_packet 的限制，服务端也会报错，导致写入或者更新失败。

```
mysql> show global variables like '%max_allowed_packet%';
+--------------------------+------------+
| Variable_name            | Value      |
+--------------------------+------------+
| max_allowed_packet       | 1048576   |
+--------------------------+------------+
```

可以通过如下命令临时修改，
```
mysql> set global max_allowed_packet = 4 * 1024 * 1024;
```

如要长期生效，则需要修改数据库配置文件，并重启 MySQL 服务。
```
max_allowed_packet = 4M
```

