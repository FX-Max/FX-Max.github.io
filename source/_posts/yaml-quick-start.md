---
title: YAML语言初识
date: 2021-09-22 00:16:18
cover: 'https://cdn.jsdelivr.net/gh/FX-Max/cdn/blog/post/2021/cover-20211009-yaml.png'
categories: Docker
tags: [Docker , YAML]
---

日常工作中，我们经常会遇到 YAML，例如 docker-compose 配置，ELK 中的 filebeat 配置， K8S 集群配置，ansible 的 playbook 等，也有越来越多的项目使用了 YAML 作为配置文件的选型。那今天，我们就来了解下它到底是何许人也。


# 什么是 YAML

YAML 官网：[https://yaml.org/](https://yaml.org/)

YAML (YAML: YAML Ain't Markup Language) 是一种类似 XML，JSON 的数据序列化语言，是一种通用的数据串行化格式。它是主要用来写配置文件的语言，比 XML 要简洁和简单，便于人阅读理解，号称 `
一种人性化的数据格式语言` 。

正如其官网介绍，What It Is: YAML is a human friendly data serialization standard for all programming languages.

# YAML 的基本语法

YAML 配置文件的后缀为 .yml，如 docker-compose.yml。

基本语法

* 大小写敏感
* 使用缩进表示层级关系
* 缩进不允许使用 tab，仅允许空格
* 缩进的空格数目不重要，只要相同层级的元素左侧对齐即可
* `#` 表示注释

最基本的一个文件结构如下，demo.yml 
```
apiVersion: v1
kind: Pod
```

若是要在一个文件中进行多个文档配置，则多个文档之间需要使用“---”(三个横线)作为分隔符。例如 demo2.yml

```
---
apiVersion: v1
kind: Pod

---
apiVersion: v2
kind: Pod
```

# YAML 的几种数据结构

YAML 支持的基础数据结构有三种。

* 对象（Maps）：键值对的集合，又称为映射（mapping）/ 哈希（hashes） / 字典（dictionary）
* 数组（Lists）：一组按次序排列的值，又称为序列（sequence） / 列表（list）
* 纯量（scalars）：单个的、不可再分的值

## Maps (对象)

Maps 键值对使用冒号结构表示，key: value，冒号后面需要加一个空格。
也可以使用 key:{key1: value1, key2: value2, key3: value3} 来表示（一般不常用）。

```
apiVersion: v1 
kind: Pod
```

上面的例子中，表示有两个键：`apiVersion` 和 `kind` ，它们对应的值分别是 `v1` 和 `Pod` 。上面的 YAML 文件转换成 JSON 格式如下：
```
{
	"apiVersion": "v1",
	"kind": "pod"
}
```

下面来看一些复杂的情况：

```

---
apiVersion: v1
kind: Pod
metadata:
  name: k8s-web-pod
  labels:
    app: web
```
该配置文件中，`metadata` 这个 key 对应的 value 就是一个 Maps，并且下一层的 `labels` 对应的 value 又是一个 Maps，实际使用中，可能会有多层的嵌套。
上面的 YAML 文件转换成 JSON 文件如下：

```
{
	"apiVersion": "v1",
	"kind": "Pod",
	"metadata": {
		"name": "k8s-web-pod",
		"labels": {
			"app": "web"
		}
	}
}
```

> 前面提到了，在 YAML 文件中，一定不要使用 tab，层级中的缩进没有做具体规定，只要保持一致即可，我们所在的团队中使用两个空格。YAML 解析器根据缩进来处理内容之间的关联性。

## Lists (数组)

一组连线 `-` 开头的行，构成一个数组。在 YAML 中我们可以这样定义：

```
---
 - Java
 - Python
 - Go
 - PHP
```

```
[
	"Java",
	"Python",
	"Go",
	"PHP"
]
```

```
---
- 
 - Java
 - Python
 - Go
 - PHP

- 
 - Java2
 - Python2
 - Go2
 - PHP2
```

```
[
	[
		"Java",
		"Python",
		"Go",
		"PHP"
	],
	[
		"Java2",
		"Python2",
		"Go2",
		"PHP2"
	]
]
```

## 复合结构

```
---
 language:
 - Java
 - Python
 - Go
 - PHP
```


