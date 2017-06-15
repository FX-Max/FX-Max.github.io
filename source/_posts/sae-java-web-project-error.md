---
title: SAE 部署 JavaWeb 项目报404错误
date: 2016-03-26 23:03:56
categories: JAVA
tags: [SAE , JAVA]
---

今天写了一个小的 JavaWeb 项目传到 SAE 上，访问的时候出错。本地测试是正常的，而且以前做微信平台开发的时候上传的项目就可以正常访问。于是花了两个小时的时间终于找出了错误的原因。

错误信息如下：
> Error 404 – Not Found.No context on this server matched or handled this request.
Contexts known to this server are

<!-- more -->

根据网上的资料，可能是项目中的 servlet-api.jar 等 jar 包与 SAE 平台提供的 jar 包相冲突。于是将项目打包成 war 包后，删除 lib 下的相关 jar　包。重新上传测试，发现还是报相同的错误。

第一步不成，无计可施，我将项目中 web.xml 中关于 servlet 的部分删除之后，在根目录下新建一个 index.jsp 页面，重新编译上传，可以正常访问。

可见还是 Java 部分出现了问题，既然前面已经排除了 servlet-api.jar 等 jar 包冲突问题，那还会是其他什么原因呢？

再经过在网上查找，发现可能是编译使用的 jdk 版本问题。问题就是出现在这里，本机上的 jdk 版本是 1.7，而使用 SAE 需要 jdk 1.6，于是换了 1.6 的 jdk，重新编译上传，测试正常。

原来以前上传到 SAE 上项目正常访问是因为当时使用的机器上 jdk 版本是 1.6。而当前机器上的 jdk 版本是1.7。

