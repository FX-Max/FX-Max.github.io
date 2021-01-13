---
title: 三步开启hexo博客RSS
date: 2017-02-28 01:13:20
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2020/bg/bg0228.jpg'
categories:
tags: [hexo , rss]
---



最近捣鼓了一下博客的RSS，配置的过程还是十分简单的，三步开启hexo的RSS。

## 安装RSS插件
> npm install hexo-generator-feed --save

## 配置hexo配置文件_config.yml

> #RSS订阅
> plugin:
> - hexo-generator-feed
> #Feed Atom
> feed:
> type: atom
> path: atom

## 开启theme的RSS支持

一些主题已经默认开启了RSS配置，如果没有，则需要手动配置。目前博客使用的主题为Next，对应的修改文件：themes/next/_config.yml。

> subnav:
> rss: /atom.xml

## 本地测试生成RSS

> hexo clean
> hexo g
> hexo s

hexo命令的简单说明可以参考之前的一篇博文：[hexo使用札记-常用命令](https://www.maxfang.me/2016/06/19/hexo-series-0/)

