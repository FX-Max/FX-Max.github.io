---
title: 【Prometheus+Grafana系列】监控MySQL服务
date: 2022-08-24 12:26:08
cover: 'https://cdn.immaxfang.com/images/post/2022/bg-prometheus-grafana-mysql.png'
categories: 运维
tags: [Linux , devops]
---

## 前言
前面的一篇文章已经介绍了 docker-compose 搭建 Prometheus + Grafana 服务。当时实现了监控服务器指标数据，是通过 node_exporter。Prometheus 还可用来监控很多服务，比如常见的  MySQL。本文就介绍如何通过 mysqld_exporter 来监控 MySQL 指标。

## 下载安装包
```php
cd /opt
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.14.0/mysqld_exporter-0.14.0.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.14.0.linux-amd64.tar.gz
mv mysqld_exporter-0.14.0.linux-amd64 mysqld_exporter
mv /opt/mysqld_exporter /usr/local/
```

## 创建监控账号并授权
在需要监控的mysql上创建账号并授权。
```php
# 创建用户
CREATE USER 'prometheus'@'%' IDENTIFIED BY 'prometheus';
# 分配权限
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'prometheus'@'%';
```

## 添加数据库监控账号配置
vim /usr/local/mysqld_exporter/.my.cnf
添加如下内容
```php
[client]
user=prometheus
password=prometheus
port=3306
```

## 启动exporter客户端
```php
/usr/local/mysqld_exporter/mysqld_exporter --config.my-cnf=/usr/local/mysqld_exporter/.my.cnf
```
先手动启动exporter看一下日志，若有错误根据输出调整即可。手动运行没问题后，则进行下一步将其添加到系统服务中。

## 添加到系统服务
vim /etc/systemd/system/mysqld_exporter.service
添加如下内容
```php
[Unit]
Description=mysqld_exporter
After=network.target
[Service]
ExecStart=/usr/local/mysqld_exporter/mysqld_exporter --config.my-cnf=/usr/local/mysqld_exporter/.my.cnf
Restart=on-failure
[Install]
WantedBy=multi-user.target
```

## 加载并重启服务
```php
# 加载配置
systemctl daemon-reload
# 启动服务
systemctl restart mysqld_exporter.service
# 查看服务状态
systemctl status mysqld_exporter.service
# 配置开机启动
systemctl enable mysqld_exporter.service
```

## 查看收集数据
访问exporter服务地址，查看数据收集情况。
```php
curl http://192.168.2.192:9104/metrics
```

## 修改 prometheus 配置文件，添加新节点
修改 prometheus 下的配置，prometheus.yml，添加如下内容。
```php
scrape_configs:  
  # 添加job
  - job_name: 'mysql-192'
    static_configs:
     # 配置监控端，即上面我们启动的 mysqld_exporter 服务
     - targets: ['192.168.2.192:9104']
       labels:
          instance: mysql
```

## 重启 prometheus 服务
上一步修改了 prometheus.yml，需要重启下 prometheus 服务。
```php
cd /var/workspace/docker-prometheus
docker-compose stop prometheus
docker-compose up -d --build prometheus
```

## 查看 prometheus 中服务添加情况
查看 targets 是否添加成功
![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-1.png)

查看 mysql 监控信息
> mysql_global_status_aborted_clients

![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-2.png)

## 在 grafana 中添加 data sources

![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-3.png)

![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-4.png)

![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-5.png)
添加 prometheus 服务地址，此处由于服务是基于 docker-compose 构建的，没有填写ip，直接填写服务名即可。

## 在 grafana 中导入 mysql 监控
![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-6.png)
输入官方模版 id，7362，点击 load。然后按照下图选择确认即可。
![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-7.png)

## 监控展示
上一步导入成功后，会自动跳转到监控面板页面，如下图。默认的格式已经非常丰富可以直接使用了，也可以根据自己需求调整位置和配置。
![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/post-pgm-8.png)
