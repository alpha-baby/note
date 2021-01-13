# kubetnetes 安装

## 使用kubeeasz工具安装

[kubeasz Github](https://github.com/easzlab/kubeasz/)

> 参考文档
> https://github.com/easzlab/kubeasz/blob/master/docs/setup/offline_install.md

# 使用kubeasz安装命令

CentOS7 安装依赖

```bash
# 文档中脚本默认均以root用户执行
# 安装 epel 源并更新
yum install epel-release -y
yum update
# 安装依赖工具
yum install python python-pip -y
```

```bash
export release=2.2.3
curl -C- -fLO --retry 3 https://github.com/easzlab/kubeasz/releases/download/${release}/easzup
chmod +x ./easzup
./easzup -D -d 19.03.14 -k v1.18.14
./easzup -S
docker exec -it kubeasz easzctl start-aio
# 销毁集群
docker exec -it kubeasz easzctl destroy
```

> 注意
> 在安装的时候是需要ssh去访问远程或者本地的机器，所以可能需要配置ssh免密访问

# 验证安装

如果提示kubectl: `command not found`，退出重新ssh登录一下，环境变量生效即可

``` bash
$ kubectl version         # 验证集群版本     
$ kubectl get node        # 验证节点就绪 (Ready) 状态
$ kubectl get pod -A      # 验证集群pod状态，默认已安装网络插件、coredns、metrics-server等
$ kubectl get svc -A      # 验证集群服务状态
```

如果还是提示：`command not found`,可以手动添加下环境变量

```bash
# zsh
echo 'export PATH=$PATH:/etc/ansible/bin' >> ~/.zshrc
source ~/.zshrc
# bash
echo 'export PATH=$PATH:/etc/ansible/bin' >> ~/.bashrc
source ~/.bashrc
```

# 配置访问

我们安装的集群一般都是在远程，那么我们就需要在本地配置`kubectl`的配置

## 生成kubeconfig

如果你是管理员就直接使用在远程节点上安装好k8s集群后自动生成的配置文件`~/.kube/config`

如果你想生成一些权限更小的用户配置文件，可以参考：

> https://blog.csdn.net/bbwangj/article/details/82789059
> http://www.xuyasong.com/?p=2054

## 增加本地kubeconfig

[kubecm](https://kubecm.cloud/#/zh-cn/)安装和使用



# shell脚本

```shell
#!/bin/sh
export release=2.2.3
curl -C- -fLO --retry 3 https://github.com/easzlab/kubeasz/releases/download/${release}/easzup
chmod +x ./easzup
./easzup -D -d 19.03.14 -k v1.18.14
./easzup -S
docker exec -it kubeasz easzctl start-aio
```

# 清理

在宿主机上，按照如下步骤清理

- 清理集群 `docker exec -it kubeasz easzctl destroy`
- 清理运行的容器 `./easzup -C`
- 清理容器镜像 `docker system prune -a`
- 停止docker服务 `systemctl stop docker`
- 删除docker文件

```bash
umount /var/run/docker/netns/default
umount /var/lib/docker/overlay
rm -rf /var/lib/docker /var/run/docker
```

上述清理脚本执行成功后，建议重启节点，以确保清理残留的虚拟网卡、路由等信息。