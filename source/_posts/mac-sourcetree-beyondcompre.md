---
title: Mac下SourceTree安装BeyondCompare
date: 2020-03-14 00:03:14
cover: 'https://cdn.immaxfang.com/images/post/2020/bg/bg0314.jpg'
categories: 
tags: [mac , git , sourcetree , beyondcompre ]
---


使用git的同学对SourceTree一定不陌生，可以很方便的进行git操作。但是其自带的文件对比工具却不太好用，在有大量文件冲突的情况下，有好的文件对比工具可以很大的提高效率。

BeyondCompare则是一个很优雅，且功能强大的文件对比工具，可以很方便的比较两个文件的差异，而且可以很好的集成到SourceTree中，windows下的安装本文就不介绍了，本文主要讲一下osx下SourceTree集成BeyondCompare工具。

## 1.首先我们默认已经安装好了SourceTree(神马，还没有装，震惊！)。

<!-- more -->   
    
## 2.下载BeyondCompare并安装

BeyondCompare官方下载地址：[http://www.scootersoftware.com/download.php](http://www.scootersoftware.com/download.php)

BeyondCompare是收费的，虽然价格有点贵，但是绝对值得入手！
当然，也可以自行搜索各种黑科技，但是品质不保证。

## 3.将BeyondCompare加入系统命令

> ln -s /Applications/Beyond\ Compare.app/Contents/MacOS/bcomp /usr/local/bin/

此处的 /Applications/Beyond\ Compare.app/Contents/MacOS/bcomp 可以根据自己的实际情况来进行调整。

## 4.在SourceTree中配置

SourceTree->Preferences->Diff，设置External Diff/Merge。

> Visual Diff Tool: Other

> Diff Command:    /usr/local/bin/bcomp

> Arguments:	$LOCAL $REMOTE

> Merge Tool:	Other

> Merge Command:	/usr/local/bin/bcomp

> Arguments:	$LOCAL $REMOTE $BASE $MERGED


重启SourceTree使配置生效。

## 5.使用

在SourceTree中选中文件，使用快捷键 Conmmand+D 即可调出BeyondCompare对文件进行对比，非常方便。




