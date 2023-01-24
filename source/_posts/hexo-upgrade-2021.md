---
title: hexo 升级5.4.0出现错误解决方法-hexo-theme-butterfly
date: 2021-09-27 00:39:59
cover: 'https://cdn.immaxfang.com/images/post/2021/cover-20211007-hexo.jpeg'
categories: hexo
tags: [hexo]
---


周末升级了下 hexo 到新版本，发现升级后，构建时出现了一些错误，以下是出现的问题，及解决方法。

* WARN  Deprecated config detected: "external_link" with a Boolean value is deprecated. See https://hexo.io/docs/configuration for more details.

<!-- more -->

修改 _config.yml 文件，将如下内容做调整。

```
external_link: true
```

将上面的内容，修改为如下内容。

```
external_link:
  enable: true # Open external links in new tab
  field: site # Apply to the whole site
  exclude: ''
```


* err: TypeError: Cannot read property 'bind' of undefined

```
err: TypeError: Cannot read property 'bind' of undefined
...
Script load failed: %s themes/butterfly/scripts/filters/post_lazyload.js
```

一般出现类似错误是由于升级hexo后，其余依赖未升级完全，可以考虑删除依赖，重新 install。

```
npm cache clean --force
rm -rf node_modules
rm package-lock.json
npm install
hexo clean
hexo g
```

可以参考git主题项目中的 [issues-406](https://github.com/jerryc127/hexo-theme-butterfly/issues/406) 。
