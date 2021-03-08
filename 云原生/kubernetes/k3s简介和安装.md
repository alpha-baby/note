## k3s 简介

https://docs.rancher.cn/docs/k3s/_index

## k3s 安装

https://docs.rancher.cn/docs/k3s/quick-start/_index

```bash
# 安装好后可以用如下命令来查看
$ kubectl get pod -A
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   metrics-server-86cbb8457f-jqwml           1/1     Running     0          26m
kube-system   local-path-provisioner-7c458769fb-4p8qh   1/1     Running     0          26m
kube-system   coredns-854c77959c-rfmwb                  1/1     Running     0          26m
kube-system   helm-install-traefik-thbfd                0/1     Completed   0          26m
kube-system   svclb-traefik-kggrk                       2/2     Running     0          25m
kube-system   traefik-6f9cbd9bd4-pnxk6                  1/1     Running     0          25m
```

移植 `kubectl` 配置文件到本地，比如我这里是把`k3s`安装到了本地虚拟机中，如果我想在本地的mac上访问安装好的`k3s`集群，可以如下操作：

```bash
# centos7-k3s 是你虚拟机的IP
$ scp root@centos7-k3s:/etc/rancher/k3s/k3s.yaml ${HOME}/.kube/local-k3s-config.bak
# 复制出来的配置文件(local-k3s-config.bak)里面的IP是 127.0.0.1 需要改成你虚拟机的 IP
# 然后测试下
$ kubectl --kubeconfig=${HOME}/.kube/local-k3s-config.bak get pod -A
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   metrics-server-86cbb8457f-jqwml           1/1     Running     0          26m
kube-system   local-path-provisioner-7c458769fb-4p8qh   1/1     Running     0          26m
kube-system   coredns-854c77959c-rfmwb                  1/1     Running     0          26m
kube-system   helm-install-traefik-thbfd                0/1     Completed   0          26m
kube-system   svclb-traefik-kggrk                       2/2     Running     0          25m
kube-system   traefik-6f9cbd9bd4-pnxk6                  1/1     Running     0          25m
```

如果你本地很多`kubeconfig`文件可以使用[kubecm](https://kubecm.cloud/#/zh-cn/install)工具来优雅的管理它们
