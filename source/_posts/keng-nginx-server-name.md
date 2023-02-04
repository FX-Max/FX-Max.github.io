---
title: 【踩坑日记】nginx server_name配置多域名的坑
date: 2023-02-04 20:30:58
categories: [nginx, 踩坑日记]
tags: [nginx, 踩坑日记]
---


# 问题介绍
项目配置了多个域名，如下，php 代码中有获取 `$_SERVER['SERVER_NAME']` 的值。

```c
server {
	server_name a.demo.com b.demo.com;
    ...
}
```

当访问 `a.demo.com` 时，其获取的值是符合预期的。但是当访问 `b.demo.com` 时，其获取的值还是 `a.demo.com`，导致代码中的判断出现错误。

<!-- more -->

# 问题分析
当 nginx 的一个 server 节点下，server_name 配置多个域名时，$server_name 变量的值是配置的第一个域名。结合上面我们的配置，此时我们的 $server_name 值为 `a.demo.com`。

# 解决方案

- 方案 1，将多个域名配置在不同的 server 段下（推荐）。

例如上面的配置，可以改成如下：

```c
server {
	server_name a.demo.com;
    ...
}
server {
	server_name b.demo.com;
    ...
}
```

- 方案 2，修改 nginx 的 SERVER_NAME 值，使用 $host 变量。

```c
# 默认
fastcgi_param SERVER_NAME $server_name;
# 修改为
fastcgi_param SERVER_NAME $host;
```
