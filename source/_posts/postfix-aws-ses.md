---
title: ubuntu使用postfix和AWS-SES发送邮件
date: 2022-06-11 01:27:01
cover: 'https://cdn.immaxfang.com/images/post/2022/bg-postfix-aws-ses.png'
categories: AWS
tags: [AWS , ubuntu]
---


在日常开发中，邮件发送是个比较常见的场景。因此出现了很多相关的软件和服务，各大云厂商也推出自己的邮件服务。今天笔者就像大家介绍一种常见的组合，AWS的邮件服务 SES 与邮件服务器 postfix 的配置和使用方法。
# 概述

- 什么是 AWS-SES

Amazon Simple Email Service (SES) 是一种经济高效、灵活且可扩展的电子邮件服务，使开发人员能够从任何应用程序中发送电子邮件。 您可以快速配置Amazon SES 以支持多种电子邮件使用案例，包括交易、营销或群发电子邮件通信。

<!-- more -->

- 什么是 postfix

Postfix 是一种电子邮件服务器，它是由任职于IBM华生研究中心（T.J. Watson Research Center）的荷兰籍研究员Wietse Venema为了改良sendmail邮件服务器而产生的。
它是为了改良 sendmail 产生的，同时它兼容 sendmail，是比较常用的一种邮件服务器。
# 开通Amazon Simple Email Service (SES)服务

- 创建一个 identity

![post-start-ses-1.png](https://cdn.immaxfang.com/images/post/2022/post-start-ses-1.png)

此处我们为了演示方便，使用`Email address`方式来验证。按下图填入后续要发送邮件的邮箱，随后 AWS 会给对应邮箱发一个确认验证的邮件，点击一下邮件连接即可表示确认授权。

![post-start-ses-2.png](https://cdn.immaxfang.com/images/post/2022/post-start-ses-2.png)

- 创建凭证

选择 Account dashboard，此处的 SMTP endpoint 就是我们的邮件服务器地址，后面配置邮件服务器的时候需要使用。

![post-start-ses-3.png](https://cdn.immaxfang.com/images/post/2022/post-start-ses-3.png)

点击创建凭证，创建好后，新页面会有下载按钮，一定要及时下载凭证文件。
凭证文件里有 Smtp Username 和 Smtp Password，后面配置 postfix 邮件服务器的时候需要用到。

![post-start-ses-4.png](https://cdn.immaxfang.com/images/post/2022/post-start-ses-4.png)

- 测试邮件发送

使用 AWS 自带的功能发送一下测试邮件，查看是否成功。

![post-start-ses-5.png](https://cdn.immaxfang.com/images/post/2022/post-start-ses-5.png)

- 其他说明

SES 的验证方式支持单个邮箱验证和 domain 验证。本文中笔者为了演示简单，采用了单个邮箱验证，如果实际使用中，邮件发送者就是固定的几个邮箱，采用该方法就比较简单。若是邮件发送者比较多，不固定，每个邮箱验证一次不太现实，就可以采用 domain 验证的方式，由域名管理员来配合验证即可，具体的使用 dimain 方式验证的方法，可以参考 aws 官网文档，添加对应的 dns 记录即可。

至此， SES 服务已经初步开通完毕，下面我们来看下 postfix 的相关配置。
# EC2 安装 postfix 并配置 SES 发送邮件
笔者的环境是 ubuntu 20.04，其他版本的 ubuntu 方法基本类似。
```bash
shell> cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.3 LTS"
```

- 安装 postfix 邮件服务

使用如下命令安装，安装过程中间直接选择默认的配置一路确认即可，后面我们单独修改配置。
```bash
sudo apt-get install mailutils -y
```
安装完成之后，在 AWS 的 EC2 上是无法直接使用 mail 命令发邮件的，需要配置邮件服务器。
此处我们以 AWS 的 SES 服务为例，配合 postfix 进行邮件发送。

- 修改 postfix 配置
```bash
sudo postconf -e "relayhost = [email-smtp.us-west-2.amazonaws.com]:587" \
"smtp_sasl_auth_enable = yes" \
"smtp_sasl_security_options = noanonymous" \
"smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
"smtp_use_tls = yes" \
"smtp_tls_security_level = encrypt" \
"smtp_tls_note_starttls_offer = yes"

sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
```
通过上述命令修改 postfix 的配置，其实修改的就是 `/etc/postfix/main.cf` 文件，也可以手动使用 vim 等修改，为了保持格式，直接使用自带的 postconf 命令修改即可。
注意：上述命令中的 `email-smtp.us-west-2.amazonaws.com`根据实际情况换成你自己开通的 SES 服务的地址，上文 SES 开通部分有介绍过。

- 填写账号文件
```bash
vim /etc/postfix/sasl_passwd
# 输入如下内容
[email-smtp.us-west-2.amazonaws.com]:587 SMTPUSERNAME:SMTPPASSWORD
```
> email-smtp.us-west-2.amazonaws.com：换成你自己的 SES 服务地址
> SMTPUSERNAME：SMTP用户名，上文 SES 开通部分有介绍过
> SMTPPASSWORD：SMTP密码，同上

- 编码账号文件和修改权限
```bash
sudo postmap hash:/etc/postfix/sasl_passwd

sudo chown root:root /etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl_passwd
sudo chmod 0600 /etc/postfix/sasl_passwd.db
```

- 重启 postfix 服务
```bash
systemctl reload postfix
```

- 测试邮件发送并查看日志
```bash
echo test | mail -s "test message" -a "From: sender@example.com" receiver@example.com

tail -f /var/log/mail.log
```
注意，此处的发送者和收件者邮件需要在 AWS 上进行验证，否则发送邮件会失败。验证方式见前面的 AWS开通 SES 服务部分。
> 如果 SES 是在 sandbox 环境中，则发送者 `sender@example.com`和 收件人`receiver@example.com`都需要在 AWS 上进行验证。如果是在 production 环境中，则只需要发送者邮件验证通过即可。

![post-postfix-aws-ses](https://cdn.immaxfang.com/images/post/2022/post-postfix-aws-ses.png)

- 其他说明

若按照如上配置方式，邮件还是发送失败，可以查看机器上的日志，如`/var/log/mail.log`。还可以检查安全组，看是否是邮件相关端口未开放。

参考文档：[https://docs.aws.amazon.com/ses/latest/dg/postfix.html](https://docs.aws.amazon.com/ses/latest/dg/postfix.html)

----
更多技术文章，请关注我的个人博客 [www.immaxfang.com](https://www.immaxfang.com/) 和小公众号 `Max的学习札记`。
