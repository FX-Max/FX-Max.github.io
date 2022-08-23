---
title: Prometheus+Grafana监控-基于docker-compose搭建
date: 2022-08-23 22:40:33
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/bg-prometheus-grafana-docker-compose-build.png'
categories: 运维
tags: [Linux , devops]
---

# 前言

## Prometheus
Prometheus 是有 SoundCloud 开发的开源监控系统和时序数据库，基于 Go 语言开发。通过基于 HTTP 的 pull 方式采集时序数据，通过服务发现或静态配置去获取要采集的目标服务器，支持多节点工作，支持多种可视化图表及仪表盘。
贴一下官方提供的架构图：
![image.png](https://raw.githubusercontent.com/FX-Max/cdn/master/blog/post/2022/pgd-1.png)

Pormetheus 几个主要模块有，Server，Exporters，Pushgateway，PromQL，Alertmanager，WebUI等，主要逻辑如下：

- Prometheus server 定期从静态配置的 targets 或者服务发现的 targets 拉取数据。
- 当新拉取的数据大于配置内存缓存区时，Prometheus 会将数据持久化到磁盘（如果使用 remote storage 将持久化到云端）。
- Prometheus 配置 rules，然后定时查询数据，当条件触发时，会将 alert 推送到配置的 Alertmanager。
- Alertmanager 收到警告时，会根据配置，聚合、去重、降噪等操作，最后发送警告。
- 可以使用 API，Prometheus Console 或者 Grafana 查询和聚合数据。

## Grafana
Grafana 是一个开源的度量分析及可视化套件。通过访问数据库（如InfluxDB、Prometheus），展示自定义图表。

## Exporter
Exporter 是 Prometheus 推出的针对服务器状态监控的 Metrics 工具。目前开发中常见的组件都有对应的 exporter 可以直接使用。常见的有两大类，一种是社区提供的，包含数据库，消息队列，存储，HTTP服务，日志等，比如 node_exporter，mysqld_exporter等；还有一种是用户自定义的 exporter，可以基于官方提供的 Client Library 创建自己的 exporter 程序。
每个 exporter 的一个实例被称为 target，Prometheus 通过轮询的方式定期从这些 target 中获取样本数据。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-2.png)

## 原理简介
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-3.png)

# 安装数据收集器 node-exporter

## 安装 node-exporter
```php
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0-rc.0/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
tar xvf node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
mv node_exporter-1.4.0-rc.0.linux-amd64 node_exporter
mv node_exporter /usr/local/
```
运行如下命令测试 node-exporter 收集器启动情况，正常情况下会输出服务端口。
```php
/usr/local/node_exporter/node_exporter
```

## 添加到系统服务
vim /etc/systemd/system/node_exporter.service
添加如下内容
```php
[Unit]
Description=mysqld_exporter
After=network.target
[Service]
ExecStart=/usr/local/node_exporter/node_exporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
```

## 加载并重启服务
```php
# 加载配置
systemctl daemon-reload
# 启动服务
systemctl restart node_exporter.service
# 查看服务状态
systemctl status node_exporter.service
# 配置开机启动
systemctl enable node_exporter.service
```
## 查看数据收集情况
重新起一个终端，查看数据收集情况。也可以在浏览器中查看。
```php
curl http://127.0.0.1:9100/metrics
```

# 安装 prometheus 和 grafana

## 安装 docker&docker-compose 
本文介绍的安装方法是基于 docker-compose 的，所以需要先安装相关 docker 环境。相关方法可以见笔者的其他文章，本文中不做详细介绍。

## 安装 prometheus 和 grafana
可以直接 clone 这个项目来快速搭建：
[https://github.com/FX-Max/docker-install-everything/tree/master/prometheus](https://github.com/FX-Max/docker-install-everything/tree/master/prometheus)
> 该项目是笔者弄的一个使用 docker-compose 搭建软件开发常见服务的项目，大家觉得有帮助，可以帮忙点个 star，感谢。

根据实际情况，修改 prometheus.yml 文件中的内容，将ip修改为上面安装了 node-exporter 的服务器ip即可。
然后在该目录下执行 `docker-compose up -d`即可，`docker ps`查看服务启动情况。
```php
CONTAINER ID   IMAGE              COMMAND                  CREATED        STATUS        PORTS                                      NAMES
6f360e9ab242   grafana/grafana    "/run.sh"                25 hours ago   Up 25 hours   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp  grafana
97b92b65aca6   prom/prometheus    "/bin/prometheus --c…"   25 hours ago   Up 21 hours   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp  prometheus
3f5906f07bf6   prom/pushgateway   "/bin/pushgateway"       25 hours ago   Up 25 hours   0.0.0.0:9091->9091/tcp, :::9091->9091/tcp  pushgateway
f556168c1b8b   prom/alertmanager  "/bin/alertmanager -…"   25 hours ago   Up 25 hours   0.0.0.0:9093->9093/tcp, :::9093->9093/tcp  alertmanager
```
docker-compose.yml 内容：
```php
version: "3"
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    user: root
#    restart: always
    ports:
      - "9090:9090"
    volumes:
      - ./conf/prometheus:/etc/prometheus
      - ./data/prometheus/prometheus_db:/prometheus 
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      - net-prometheus

  grafana:
    image: grafana/grafana
    container_name: grafana
    user: root
#    restart: always
    ports:
      - "3000:3000"
    volumes:
      #- ./conf/grafana:/etc/grafana
      - ./data/prometheus/grafana_data:/var/lib/grafana
    depends_on:  
      - prometheus
    networks:
      - net-prometheus

  pushgateway:
    image: prom/pushgateway
    container_name: pushgateway
    user: root
#    restart: always
    ports:
      - "9091:9091"
    volumes:
      - ./data/prometheus/pushgateway_data:/var/lib/pushgateway

  alertmanager:
    image: prom/alertmanager
    hostname: alertmanager
    container_name: alertmanager
    user: root
#    restart: always
    ports:
      - "9093:9093"
    volumes:
      - ./data/prometheus/alertmanager_data:/var/lib/alertmanager

networks:
  net-prometheus:
```
prometheus.yml 内容：
```php
global:
  scrape_interval:     5s
  evaluation_interval: 5s

  external_labels:
      monitor: 'dashboard'

alerting:
 alertmanagers:
 - static_configs:
    - targets:
        - "alertmanager:9093"

rule_files:
  #- 'alert.rules'

scrape_configs:  
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: node
    static_configs:
      - targets: ['192.168.0.103:9100','pushgateway:9091']

  - job_name: 'mysql-131'
    static_configs:
     - targets: ['192.168.0.131:9104']
       labels:
          instance: mysql
```

## 查看 prometheus 
访问 `http://127.0.0.1:9090/targets`，效果如下，上面我们通过 node_exporter 收集的节点状态是 up 状态。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-4.png)

## 配置 Grafana
访问 `http://127.0.0.1:3000`，登录 Grafana，默认的账号密码是 admin:admin，首次登录需要修改默认密码。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-5.png)

按照如下添加 data sources，将 prometheus 添加到 data sources 中。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-6.png)
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-7.png)
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-8.png)
添加 prometheus 服务地址，此处由于服务是基于 docker-compose 构建的，没有填写ip，直接填写服务名即可。

## 添加监控模版

![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-9.png)

输入官方模版 id，1860，点击 load。然后按照下图选择确认即可。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-10.png)

导入成功后，会自动跳转到监控面板页面，如下图。
![image.png](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/pgd-11.png)

# 结语
本文简单介绍了 prometheus + grafana 服务搭建流程，初步跑通了整个服务。当然它还有很多功能，后续笔者会开新的文章来分享。
## 参考文档
官方模板库：[https://grafana.com/grafana/dashboards/](https://grafana.com/grafana/dashboards/)
node 模板：[https://grafana.com/grafana/dashboards/1860](https://grafana.com/grafana/dashboards/1860)
MySQL 模板：[https://grafana.com/grafana/dashboards/7362](https://grafana.com/grafana/dashboards/7362)
docker 搭建 prometheus&grafana：[https://blog.51cto.com/keep11/4261521](https://blog.51cto.com/keep11/4261521)
