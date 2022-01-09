---
title: AWS修改RDS时区
date: 2021-07-18 23:05:40
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/cover-20211006-rds.jpeg'
categories: AWS
tags: [AWS , RDS , MySQL]
---

# 查看 RDS 当前时区

默认情况下，AWS 的 RDS 采用的是 UTC 时间。而我们地区一般位于东八区，因此我们本地的时间是 UTC+8。

连接到 RDS 上，查询当前实例的时区。

```sql
show variables where variable_name like 'time_zone';
```
显示的结果如下，表示当前 RDS 时区的 UTC。

> time_zone   UTC

# 调整 RDS 时区

RDS 的时区调整是通过调整参数组来操作的。AWS 的 RDS 是不允许修改 default 参数组的。因此先要确认下当前 RDS 采用的参数组是不是 default 参数组。如果是 default 参数组，则需要新建一个参数组。然后在该参数组上调整 timezone 相关参数，然后变更 RDS 使用的参数组，使用新的参数组。

从左侧的参数组菜单进入，即可新建参数组。一般我们都会从把当前在使用的参数组作为模版来复制一份新的来调整。
选择当前在使用的参数组，Actions->Copy即可。以笔者测试为例，当前在使用的参数组为 pg-mysql57-demo ，复制过来的新的参数组为 pg-mysql57-demo-new 。

![1](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_1.jpg)

![2](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_2.jpg)

接下来就可以修改新的参数组的参数了，点击改参数组进入详情页面，搜索关键词 time_zone，然后点击 Modify 即可对参数进行修改，从可选值中找到我们需要的值，此处我们选择 Asia/Shanghai，最后确认变更即可。

![3](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_3.jpg)

![4](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_4.jpg)

再进入参数组，搜索 time_zone ，发现值已经修改为 Asia/Shanghai，说明已经修改完毕。

![5](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_5.jpg)

参数组调增完毕了，接下来就是给对应实例应用该参数组了。
进入到需要调整的 RDS ，在参数组配置中，选择新的参数组。确认修改后，系统会提示是否立即应用修改。可以根据实际情况选择立即修改或者下一次维护窗口。修改 time_zone 需要重启数据库实例，这里我们选择下一次停机窗口重启。

![6](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/aws_rds_timezone_6.jpg)

选择合适的时机，重启 RDS 即可。


# 验证修改生效

在 RDS 重启完毕之后，再次执行上面的查询时区的语句，显示的结果如下( Asia/Shanghai)，表示时区已修改成功。

```sql
show variables where variable_name like 'time_zone';
```

> #time_zone    Asia/Shanghai

--- 

Happy Coding.
