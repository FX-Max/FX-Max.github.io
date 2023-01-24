---
title: hexo使用札记-常用命令
date: 2020-06-19 01:15:11
cover: 'https://cdn.immaxfang.com/images/post/2020/bg/bg0619.jpg'
categories:
tags:
---

今年前一段时间将博客从 jeklly 转到 hexo ，感觉还是非常好用的，hexo 的常用命令不多，本文就介绍一下使用 hexo 的常用基本命令。


## hexo cl

- 全名：hexo clean
- 清除缓存文件**db.json**和已生成的静态文件 **public**。

## hexo g

- 全名: hexo generate
- 生成网站静态文件，默认保存在**public**文件夹。

> 由于hexo源文件可读性不强，使用 **hexo g** 可以将hexo源文件生成静态文件，便于调试，生成的静态文件可以直接部署网站。 

## hero s

- 全名：hexo server
- 启动本地服务器，访问本地hexo项目，默认的访问地址是 http://localhost:4000/ ，可以很方便的在本地预览博客样式和内容。

<!-- more -->

> 修改文章内容或是修改样式代码，不需要重新运行 **hexo s** 重启本地服务器，只需要保存文件后刷新页面即可看到效果。
> 若是修改了hexo根目录下的 **_config.yml** ，则需要重新运行 **hexo s** 命令重启本地服务器。 

## hero d

- 全名：hexo deploy
- 生成网站的静态文件，并将其部署到 **_config.yml** 文件中配置的仓库中。

## hexo n page xxx

- 全名：hexo new page xxx
- 新建一个名为 **xxx** 的页面，文件地址为 **source/xxx/index.md**  。

> 使用该命令生成的文件名，可以手动在项目中进行重命名，同时生成的页面不会出现在文章列表和归档文件中，也不支持设置分类和标签。
> 若需要删除该页面，只需要手动删除 **source/xxx** 目录即可。

## hexo n xxx

- 全名：hexo new xxx
- 新建一篇名为 **xxx** 的文章，文件地址为 **source/_posts/xxx.md** 。

> 使用该命令生成的文章名，可以在项目中手动进行修改。
> 如果文章名中有空格，则文章名需要使用 **""** ，例如 hexo new "hello world"。
> 若需要删除某篇文章，只需要手动删除 **source/_posts/xxx.md** 文件即可。


## 参考

- [hexo中文文档](https://hexo.io/zh-cn/docs/commands.html)


---

Happy Coding.
