---
title: 【k8s入门】Kubernetes v1.25创建ServiceAccount未生成Secret问题
date: 2023-02-23 00:20:58
categories: [k8s]
tags: [k8s]
---

# 说明

> kubernetes v1.24.0 更新之后进行创建 ServiceAccount 不会自动生成 Secret 需要对其手动创建。

网上的很多教程都没有创建 Secret 这步，应该是之前版本的教程，笔者使用的是 v1.25 版本，这部分需要特别添加。
以下以创建一个 jenkins 用户为例，演示下在新版本下如何操作。该用户的作用是后续会在 jenkins 中调度集群。

<!-- more -->

# 创建

```bash
cat >role-jenkins.yaml<<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jenkins
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-jenkins
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: v1
kind: Secret
metadata:
  name: jenkins
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "jenkins"
type: kubernetes.io/service-account-token
EOF
```

```bash
# 创建 ServiceAccount 和 Secret
kubectl apply -f role-jenkins.yaml
# 获取 Secret
kubectl -n kube-system get secrets
# 查看 Secret 详情
kubectl -n kube-system describe secrets jenkins
# 获取 Token
kubectl -n kube-system get secrets jenkins -o go-template --template '{{index .data "token"}}' | base64 --decode
```

# 参考

https://stackoverflow.com/questions/72256006/service-account-secret-is-not-listed-how-to-fix-it

https://blog.csdn.net/qq_33921750/article/details/124977220

<center>![avatar](https://cdn.immaxfang.com/base/mpwechat.png)</center>