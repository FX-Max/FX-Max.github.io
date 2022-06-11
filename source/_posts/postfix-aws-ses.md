---
title: ubuntu使用postfix和AWS-SES发送邮件
date: 2022-06-11 01:27:01
cover: ''
categories: AWS
tags: [AWS , ubuntu]
---

- 前言

需要提前开通 AWS 的 SES 服务，开通方法见笔者前面的文章。
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
此处我们以 AWS 的 SES 服务为例，配合 postfix 进行邮件发送。SES 的申请和验证操作，请参考我前面的文档，此处不再赘述。

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
注意：上述命令中的 `email-smtp.us-west-2.amazonaws.com`根据实际情况换成你自己开通的 SES 服务的地址。

- 填写账号文件
```bash
vim /etc/postfix/sasl_passwd
# 输入如下内容
[email-smtp.us-west-2.amazonaws.com]:587 SMTPUSERNAME:SMTPPASSWORD
```
> email-smtp.us-west-2.amazonaws.com：换成你自己的 SES 服务地址
> SMTPUSERNAME：SMTP用户名，参考我前面的 AWS  开通 SES 服务文档
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
注意，此处的发送者和收件者邮件需要在 AWS 上进行验证，否则发送邮件会失败。验证方式见笔者前面的 AWS开通 SES 服务文章。
> 如果 SES 是在 sandbox 环境中，则发送者 `sender@example.com`和 收件人`receiver@example.com`都需要在 AWS 上进行验证。如果是在 production 环境中，则只需要发送者邮件验证通过即可。

![post-postfix-aws-ses](https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2022/post-postfix-aws-ses.png)

参考文档：[https://docs.aws.amazon.com/ses/latest/dg/postfix.html](https://docs.aws.amazon.com/ses/latest/dg/postfix.html)

