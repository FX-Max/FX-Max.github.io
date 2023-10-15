---
title: Nexus3 重置 admin 账号密码
date: 2023-06-14 00:46:32
categories:
tags:
---


# 问题背景

nexus3 的 admin 账号密码忘记了，需要重置。

# 环境说明

```
nexus 基于 docker-compose 部署，版本 nexus3.26
docker 镜像 sonatype/nexus3:3.26.1
```

# 操作步骤

参考： https://support.sonatype.com/hc/en-us/articles/213467158-How-to-reset-a-forgotten-admin-password-in-Nexus-3-x

<!-- more -->

## 停止 nexus 服务
由于 nexus 是基于 docker 部署，后面我们需要进入容器中执行相关命令，所以此处不能直接使用 `docker stop xxx` 来关闭服务。需要进入到容器内部来关闭 nexus 服务。

```
# 进入 docker 容器内，注意，此处使用 root 用户，否则后续命令会无权限
docker exec -u root -it nexus3 /bin/bash
# 停止服务
/opt/sonatype/nexus/bin/nexus stop
# 核对服务状态
/opt/sonatype/nexus/bin/nexus status
```

说明：此处 docker 容器中 nexus 服务关闭的情况可能各不相同，此处找到了镜像原始 dockerfile，从中服务启动时执行的路径，推测出其关闭服务的命令。启动服务命令是  `CMD ["/opt/sonatype/nexus/bin/nexus", "run"]`，则尝试使用 `/opt/sonatype/nexus/bin/nexus stop` 来关闭服务。
参考： https://github.com/sonatype/docker-nexus3/blob/main/Dockerfile 

## 进入 OrientDB 控制台

```
java -jar $NEXUS_HOME/lib/support/nexus-orient-console.jar
```

> 需要根据 nexus 各自的安装情况执行上述命令。

参考： https://support.sonatype.com/hc/en-us/articles/115002930827-Accessing-the-OrientDB-Console

## 进入数据库

```
# 查看 db 目录，根据实际情况查找到目录
ls -alh nexus-data/db/security
# 连接数据库，此处 `nexus-data/db/security` 根据实际 db 目录进行调整
connect plocal:nexus-data/db/security admin admin
```

## 调整 admin 账号密码

```
# 查看 admin 用户信息
select * from user where id = "admin"
# 更新 admin 用户的密码为 admin123
update user SET password="$shiro1$SHA-512$1024$NE+wqQq/TmjZMvfI7ENh/g==$V4yPw8T64UQ6GfJfxYq2hLsVrBY8D1v+bktfOxGdt4b/9BthpWPNUy/CBk6V9iA0nHpzYzJFWO8v/tZFtES8CA==" UPSERT WHERE id="admin"
```

注意：为了方便，此处先临时将密码更新为 `admin123`。
若要退出 OrientDB 控制台，输入 `exit;` 即可退出。

```
orientdb {db=security}> exit;
```

## 恢复 nexus 服务
```
# 启动服务
/opt/sonatype/nexus/bin/nexus start
# 核对服务状态
/opt/sonatype/nexus/bin/nexus status
```

## 验证账号

使用 `admin:admin123` 帐密来登录 nexus 服务，验证是否调整正确。若确认调整成功，建议及时使用更复杂的密码替换临时密码 `admin123` 。

# 问题记录

- 报没有权限
> Error creating history file java.io.IOException: Permission denied at java.io.UnixFileSystem.createFileExclusively(Native Method) at java.io.File.createNewFile(File.java:1012) at

一开始使用 `docker exec -it nexus3 /bin/bash` 进入容器，执行进行 OrientDB 命令时，会报无权限，且无法使用 `sudo su` 切换用户。使用 `docker exec -u root -it nexus3 /bin/bash` 即可。

参考： https://gist.github.com/marcelmaatkamp/123e8793e07a72a382d8d0e8d66bbd8f?permalink_comment_id=3276537


# 文档参考

[How to reset a forgotten admin password in Sonatype Nexus Repository 3](https://support.sonatype.com/hc/en-us/articles/213467158-How-to-reset-a-forgotten-admin-password-in-Nexus-3-x)
[Nexus3.X忘记admin密码找回](https://www.cnblogs.com/forever521Lee/p/10919512.html)
