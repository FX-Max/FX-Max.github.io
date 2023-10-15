---
title: 将 hexo 博客部署到 Cloudflare Pages
date: 2023-10-15 22:21:12
categories:
tags:
---


# 背景

以前做活动买了一台阿里云的轻量级服务器部署博客，近期快到了发现续费挺贵，就不打算续了，准备把博客迁移走。需求有几点，
- 稳定且尽可能费用低，免费更好。
- 访问速度好，尽可能保证国内海外都有好的访问体验。
- 方便迁移和部署。

综合考虑之后，决定迁移到 Cloudflare 上来。公司不少服务使用的都是 CF，功能强大，同时对于个人来讲，它提供的免费服务也非常适合我们部署一些个人服务。不得不说， Cloudflare 真是一家有格局的公司。

  # Cloudflare 部署方式
  
我的博客是基于 hexo，Cloudflare 上有两种常见的部署方式。

1. Cloudflare Pages 部署
类似于 GitHub Pages 的静态网站托管服务，直接可以部署在 Cloudflare 的几个百数据中心上。

2. Cloudflare Workers 部署
Cloudflare Workers Site 可以与常见的静态网站生成器（Hexo、Hugo、Jekyll、Gatsby 等）兼容。Cloudflare Workers Site 是 Cloudflare Workers 提供了 KV Storage（Workers KV）以后开发出的一个功能，将静态文件存储在 KV Storage 中，Cloudflare Workers 从 KV 存储中获取文件并以 HTTP 响应的形式返回，实现静态网站托管。

这两种方式都尝试了下，相对而言，Cloudflare Pages 方式更简便一些，本文主要介绍此方式。

# 前期准备

注册 Cloudflare 账号。

在 Cloudflare 中添加需要管理的域名。
【Website】-【Add a site】，填入你的域名，如 `immaxfang.com` ，选择免费版本即可，然后根据提示修改 DNS 。
由于我的博客域名在阿里云，需要先在阿里云域名管理里进行修改，将域名的 DNS 设置为 Cloudflare 的。






