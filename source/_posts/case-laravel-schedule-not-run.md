---
title: Laravel调度任务不执行问题
date: 2021-06-20 19:59:03
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/cover-20211009-laravel.png'
categories: php
tags: [php,laravel]
---


在使用 laravel 的调度任务时候，有时候会出现正确配置了调度任务，但是脚本却没有执行的情况，具体什么问题呢，今天我们来分析一下。

## 1.什么原因造成的

在使用 laravel 中的调度任务时，有些时候脚本一次的执行时间是不确定的，我们为了避免任务重复执行，会使用 withoutOverlapping 方法。withoutOverlapping 在调度任务开始时会创建一个锁，在该锁未过期之前，下一次的调度任务不会再次执行。默认情况下，这个锁的过期时间是 24h，当然也可以指定过期时间。关于这个锁的实现，会在后续文章中分析，实际上是一个互斥锁 (mutex)。

有些时候，由于一些特殊原因，导致上一次任务没有正常结束，这个锁还未过期情况下，就会出现调度任务不会执行的情况。

## 2.如何解决

这种情况下，处理的情况也比较简单，手动清除锁即可。这个锁的生成位置由 config/cache.php 指定，默认情况下，在配置的 CACHE_DRIVER 是 file 的情况下，只需要将 storage/framework/cache 下的文件删除即可。 

> Happy coding.
