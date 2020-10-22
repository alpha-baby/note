# docker 常用命令

# 镜像命令

Docker 利用容器(Container)独立运行的一个或一组应用。容器是用镜像创建的的运行实例。我们可以把镜像(image)看作是类，然而容器(container)就可以看作是对象,对象是根据类实例化而得到的。

容器是可以被启动、开始、停止、删除。每个容器都是相互隔离的、保证了完全的平台。

可以把容器看做是简易版本的Linux环境(包括root用户权限、进程空间、用户空间和网络空间等)，和运行在其中的应用程序。

## 镜像的查询

```bash
$ docker search [image name]
```

## 获取镜像

*`docker pull`*

```
docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]
```

* Docker 镜像仓库地址：地址的格式一般是 `<域名/IP>[:端口号]`。默认地址是 Docker Hub。
* 仓库名：如之前所说，这里的仓库名是两段式名称，即 `<用户名>/<软件名>`。对于 Docker Hub，如果不给出用户名，则默认为 `library`，也就是官方镜像。

比如我们可以拉取这个ubuntu18.04的镜像：

```
$ docker pull ubuntu:18.04
```

限于国内网速的原因国内从docker Hub上拉取镜像特别的慢，可以配置下加速器，推荐配置阿里的[加速器](https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors),前提是你要注册阿里云的账户。

![](https://upload-images.jianshu.io/upload_images/13859457-799426522da6d4a7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 运行镜像

*`docker run`*

```
$ docker run -it --rm \
    ubuntu:18.04 \
    bash
```

* `-it`：这是两个参数，一个是 `-i`：交互式操作，一个是 `-t` 终端。我们这里打算进入 `bash` 执行一些命令并查看返回结果，因此我们需要交互式终端。
* `--rm`：这个参数是说容器退出后随之将其删除。默认情况下，为了排障需求，退出的容器并不会立即删除，除非手动 `docker rm`。我们这里只是随便执行个命令，看看结果，不需要排障和保留结果，因此使用 `--rm` 可以避免浪费空间。
* `ubuntu:18.04`：这是指用 `ubuntu:18.04` 镜像为基础来启动容器。
* `bash`：放在镜像名后的是 **命令**，这里我们希望有个交互式 Shell，因此用的是 `bash`。

## 列出镜像

要想列出已经下载下来的镜像，可以使用 `docker image ls` 命令。
也可以使用简化的命令: `docker images`

```
$ docker image ls
REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
ubuntu               18.04               f753707788c5        4 weeks ago         127 MB
```

列表包含了 `仓库名`、`标签`、`镜像 ID`、`创建时间` 以及 `所占用的空间`。

其中仓库名、标签在之前的基础概念章节已经介绍过了。**镜像 ID** 则是镜像的唯一标识，一个镜像可以对应多个 **标签**。因此，在上面的例子中，我们可以看到 `ubuntu:18.04` 和 `ubuntu:latest` 拥有相同的 ID，因为它们对应的是同一个镜像。

## 查看镜像的详细信息

```bash
$ docker image inspect [image] 
```

## 镜像的导入导出

**镜像导出:**
```bash
$ docker image sage [docker image name or image id] > [local file]
```

**镜像导入**
```bash
$ docker image load -i [local image file]
```

导入后镜像是没有名字的,需要使用命令给镜像加上标签: `docker image tag [image id] [imageName]:[version]`



## 删除本地镜像

如果要删除本地的镜像，可以使用 `docker image rm` 命令，其格式为：

```
$ docker image rm [选项] <镜像1> [<镜像2> ...]
```

# 容器命令

容器的命令有:

|Commands |  |
|:---|:------|
|attach　|　将本地标准输入，输出和错误流附加到正在运行的容器 |
|commit　|　根据容器的更改创建新图像                         |
|cp 　|　 在容器和本地文件系统之间复制文件/文件夹            |
|create 　|　创建但不运行                                    |
|diff　　|　　检查容器文件系统上文件或目录的更改             |
|exec 　　|　在正在运行的容器中运行命令                      |
|export　|　将容器的文件系统导出为tar存档                    |
|inspect　|　显示容器的详细信息                              |
|kill 　|　杀死一个或多个正在运行的容器                      |
|logs　|　 获取容器的日志                                    |
|ls 　|　显示所有容器                                        |
|pause/unpause |  暂停／停止暂停容器                         |
|port　|　列出端口映射或容器的特定映射                       |
|prune 　|　删除所有已经停止的容器                           |
|rename　|　 给容器重新命名                                  |
|restart 　|　重新启动容器                                   |
|rm 　|　删除容器                                            |
|run 　|　 运行容器                                          |
|start/stop 　|　启动或停止容器                              |
|stats 　|　显示容器资源使用情况统计信息的实时流             |
|top 　|　查看容器运行进程                                   |
|update 　|　升级容器配置                                    |
|wait 　|　阻止，直到一个或多个容器停止，然后打印退出代码    |


## 启动容器

启动容器有两种方式，一种是基于镜像新建一个容器并启动，另外一个是将在终止状态（`stopped`）的容器重新启动。有镜像才能创建容器，这是根本前提。

因为 Docker 的容器实在太轻量级了，很多时候用户都是随时删除和新创建容器。

### 新建并启动

所需要的命令主要为 *`docker run`*。

```
docker run [OPTIONS] IMAGE [command] [ARG...]
```

[OPTIONS]

1. `-i`:以交互模式运行容器，通常与`-t`同时使用。
2. `-t`:为容器重新分配一个伪终端。
3. `--name="容器新名字"`:为容器指定一个名称。
4. `-d`:后台运行容器，并返回容器ID，即启动守护式容器。docker容器后台运行就必须有一个前台进程，容器运行的命令如果不是那些一直挂起的命令，就会自动退出。
5. `-P`:随机端口映射。
6. `-p`:指定端口映射，有以下四种方式
    - ip:hostPort:containerPort  绑定IP和端口
    - ip::containerPort  绑定某IP下的随机端口
    - hostPort:containerPort  绑定0.0.0.0:IP:IP
    - ContainerPort  绑定随机端口
    - ip::containerPort/tcp  指定协议


例如，下面的命令输出一个 “Hello World”，之后终止容器。

```
$ docker run ubuntu:18.04 /bin/echo 'Hello world'
Hello world
```

### 启动已终止容器

可以利用 `docker container start` 命令，直接将一个已经终止的容器启动运行。

容器的核心为所执行的应用程序，所需要的资源都是应用程序运行所必需的。除此之外，并没有其它的资源。可以在伪终端中利用 `ps` 或 `top` 来查看进程信息。

## 列出当前所有正在运行的容器

*`docker ps`*

```bash
docker ps [OPTIONS]
```

* `-a`, 显示所有的容器
* `-n`, 显示最近n个创建的容器
* `-l`, 显示最近创建的容器
* `-q`, 静默模式，只显示容器编号
* `-s`, 显示容器文件的大小
* `--no-trunc`, 不截断输出


## 退出容器

*`exit`*

容器停止并退出

*`ctrl+p+q`*

容器不停止退出

## 停止容器

*`docker stop`*

正常停止容器

*`docker kill`*

强制暴力停止容器

## 删除容器

*`docker rm`*

## 查看容器日志

*`docker logs -t -f --tail 3 [ID]`*

## 查看容器内的进程

*`docker top`*

## 查看容器内部细节

*`docker inspect [ID]`*

## 进入正在运行的容器

*`docker exec -it [ID] bashShell`*

*`docker attach [ID]`*

 attach 直接进入容器启动命令的终端，不会启动新的进程
 
 exec 是在容器中打开新的终端，并可以启动新的进程
 
## 把容器内的数据拷贝到宿主机
 
 *`docker cp [ID]:dir hostDir`*
 
 
