---
title: API的Authorization头里为啥有个Bearer
date: 2022-09-05 00:33:48
cover: ''
categories:
tags:
---

在我们设计和使用API授权的时候，经常会接触到如下内容：

```bash
Authorization : Bearer Tokenxxxxxx
```

为什么前面会有个Bearer，直接弄成这样不是更简单么。

```bash
Authorization : Tokenxxxxxx
```

这是因为 W3C 的 HTTP 1.0 规范，具体见 10.2 和 11 。Authorization 的格式是：

```bash
Authorization: <type> <authorization-parameters>
```

Bearer 是授权的类型，常见的授权类型有：

- Basic 用于 http-basic 认证；
- Bearer 常见于 OAuth 和 JWT 授权；
- Digest MD5 哈希的 http-basic 认证 (已弃用)
- AWS4-HMAC-SHA256 AWS 授权
- ...