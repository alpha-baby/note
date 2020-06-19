# 在线学习安装Istio和Kubernetes

> 转载 https://www.jdon.com/49655

Istio和Kubernetes很火，但是基本在Linux环境，搭建环境也不是一件容易的事情，下面这个Katacoda网址提供了在浏览器中学习Istio和Kubernetes的方式：

[Get Started with Istio and Kubernetes | Istio | Ka](https://www.katacoda.com/courses/istio/deploy-istio-on-kubernetes)

打开这个网址第一页是两个服务器的linux界面，左边引导你的操作：

第一步启动K8s：键入launch.sh将启动主从Kubernetes；键入kubectl cluster-info可查看当前k8s的集群情况：

```bash
master $ kubectl cluster-info
Kubernetes master is running at https://172.17.0.26:6443
KubeDNS is running at https://172.17.0.26:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

进入第二页是部署Istio：

Istio安装时两个部分，第一部分包括CLI工具，用于部署和管理Istio后端服务的，第二部分配置K8s集群以支持Istion。

首先安装CLI工具：

下面是直接安装Istio 1.0.0版本：

```bash
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.0 sh -
```

显示安装istio结果：

```bash
Downloaded into istio-1.0.0:
bin  install  istio.VERSION  LICENSE  README.md  samples  tools
Add /root/istio-1.0.0/bin to your path; e.g copy paste in your shell and/or ~/.profile:
export PATH="$PATH:/root/istio-1.0.0/bin"
```

然后将Istio的bin目录加入路径：

```bash
export PATH="$PATH:/root/istio-1.0.0/bin"
```

第二步是配置Istio的CRD, Istio已经通过K8s的CRD(定制资源定义)进行了扩展，通过crds.yaml部署这个扩展插件：

进入刚刚安装好的Istio 1.0.0目录，在这个目录下执行：

```bash
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
```

输出：

```bash
customresourcedefinition.apiextensions.k8s.io "adapters.config.istio.io" configured
customresourcedefinition.apiextensions.k8s.io "instances.config.istio.io" configured
customresourcedefinition.apiextensions.k8s.io "templates.config.istio.io" configured
customresourcedefinition.apiextensions.k8s.io "handlers.config.istio.io" configured
```

第三步是安装Istio使用默认的相互TLS授权，等于Https的交互的意思：

```bash
kubectl apply -f install/kubernetes/istio-demo-auth.yaml
```

这将安装Pilot, Mixer, Ingress-Controller,和Egress-Controller, 和 Istio CA (Certificate Authority).

至此，检查所有服务都被部署微Pods了：

```bash
kubectl get pods -n istio-system
```

输出：

```bash
master $ kubectl get pods -n istio-system
NAME                                        READY     STATUS              RESTARTS   AGE
grafana-66469c4d95-cdfls                    1/1       Running             0          1m
istio-citadel-5799b76c66-jg9xw              1/1       Running             0          1m
istio-cleanup-secrets-tp2bt                 0/1       ContainerCreating   0          1m
```

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfu533nyfoj30i20ba75a.jpg)

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfu53a4dhij30m20d0wg1.jpg)

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfu53jl1esj30dv0bw3z8.jpg)
