---
title: git使用命令行保留原分支迁移代码仓库
date: 2022-03-19 01:54:57
cover: 'https://cdn.immaxfang.com/images/post/2022/pg-git-migrate-project.png'
categories: git
tags: [git]
---

有些时候我们需要对git仓库中的项目进行一些迁移，如从a账号迁移到b账号下，从github平台迁移到内部的gitlab平台等。一般平台会自带 migrate 或者 import 的功能，可以很方便的进行仓库的迁移。当然，我们也可以自行进行迁移，当需要迁移的项目比较多时，脚本进行迁移更快捷。

下面来看看如何进行手动迁移，同时在迁移后，保留原项目的分支和tag，以及提交记录等。

- 先将待迁移的项目 clone 下来

```bash
git clone --mirror <url_of_old_repo>
cd <name_of_old_repo>
```

- 确保新的空仓库已经创建完成，然后即可将项目推送到新的空仓库中。

```bash
git remote rm origin
git remote add origin <url_of_new_repo>
git push origin --mirror
```

大功告成，可以看到新的仓库中，项目的分支和tag，以及提交记录等，都会保留。
