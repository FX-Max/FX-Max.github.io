---
title: Hexo 修改默认文章路径
date: 2023-01-25 13:30:44
categories: [hexo]
tags: [hexo]
---


# 修改文章默认 url

在 hexo 中新建的文章，默认的 url 路径是 `年/月/日/标题` 这样的格式，这其实是不利于 SEO 的。

可以通过修改配置文件 `_config.yml` 来调整 hexo 生成文章的展示链接。

默认的配置如下：

```
permalink: :year/:month/:day/:title/  
```

此处笔者修改为如下内容：

<!-- more -->

```
permalink: :title/
```

permalink 从原来的默认值 `:year/:month/:day/:title/` 修改成 `:title/` 之后生成文章的 url 中就没有日期了。

```
https://www.immaxfang.com/2022/07/15/beanstalkd/
```

上面修改前的 url 会变成如下的 url ：

```
https://www.immaxfang.com/beanstalkd/
```

# 自定义 url

当然，我们也可以自定义文章路径。如下面的例子，我们修改 `_config.yml` 配置一个自定义路径标签 `my` 。

```yml
permalink: :my/
```

在文章中我们给文章加入 `my` 标签，并赋予一个值。

```
---  
title: beanstalkd  
date: 2022-07-15 20:00
my: a1c9d8acb9bca455ea3e81afce35e5  
---
```

最终这篇文章的 url 会变成： `https://www.immaxfang.com/a1c9d8acb9bca455ea3e81afce35e5` 。

# 参考

https://hexo.io/zh-cn/docs/permalinks
