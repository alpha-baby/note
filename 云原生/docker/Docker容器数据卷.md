# Docker容器数据卷


# 是什么？

相当于给运行的容器插上一个移动硬盘一样，就算关闭了容器数据一样在移动硬盘里面，也就是相当于给我们运行中的容器做一个数据持久化。有时候多个容器之间想要共享数据，这样也可以用数据卷的数据来实现这样的功能。

# 能干嘛？

1. 做容器里面某些数据的持久化
2. 在多个容器之间，容器和宿主机之间的共享数据

# 数据卷的创建

在执行`docker run  ` 的时候加上 `-v` 参数

执行 *`docker run -it -v HostDir:ContainerDir:ro 镜像名`* 就能把容器内的路径和宿主机的路径做一个映射了, `ro`是写保护，不允许容器对其中进行写东西。 

- -v HostDir:ContainerDir:ro 镜像名 # 创建一个数据卷


# 数据卷容器

如果启动一个容器需要挂载很多的数据卷，这样就会有很多 `-v` 参数，docker 给我们提供了更便捷的操作。
容器挂载数据卷，其它容器通过挂载这个(父容器)实现数据共享，挂载数据卷的容器，称之为**数据卷容器**。

**数据卷容器**也就是用来做两个或者多个容器之间的数据共享。

`--volumes-from` 参数就是用来连接数据卷容器

## 实战数据卷容器

在在宿主机中创建相应的文件和目录：

```bash
$ mkdir -p /tmp/Volume/a
$ mkdir -p /tmp/Volume/b
$ touch /tmp/Volume/b/b.txt
$ touch /tmp/Volume/a/a.txt
```

创建数据卷容器：

```bash
$ docker run --name "VolumesContainer" -it -d -v /tmp/Volume/b/:/opt/b -v /tmp/Volume/a/:/opt/a/ centos:7.5.1804
```

使用数据卷容器：

```bash
$ docker run -d -p 8080:80 --volumes-from VolumesContainer --name "nginx0" nginx:1.14
$ docker run -d -p 8081:80 --volumes-from VolumesContainer --name "nginx1" nginx:1.14
```

挂载成功后的结果：

```bash
// $ docker ps -a
docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                  NAMES
08d8bb6017a3        nginx:1.14          "nginx -g 'daemon of…"   6 seconds ago        Up 5 seconds        0.0.0.0:8081->80/tcp   nginx1
9f8735de6cbc        nginx:1.14          "nginx -g 'daemon of…"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp   nginx0
c2193364f3c1        centos:7.5.1804     "/bin/bash"              6 minutes ago        Up 6 minutes                               VolumesContainer
```

## 数据卷容器应用场景

在集中管理集群中，大批量的容器都需要挂载相同的多个数据卷时可以采用数据卷容器进行统一管理
