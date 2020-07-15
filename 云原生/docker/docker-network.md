# docker network

> 引用： https://www.jianshu.com/p/22a7032bb7bd

实现原理
----

Docker使用Linux桥接（参考[《Linux虚拟网络技术》](https://www.jianshu.com/p/f86d4b88777d)），在宿主机虚拟一个Docker容器网桥(docker0)，Docker启动一个容器时会根据Docker网桥的网段分配给容器一个IP地址，称为Container-IP，同时Docker网桥是每个容器的默认网关。因为在同一宿主机内的容器都接入同一个网桥，这样容器之间就能够通过容器的Container-IP直接通信。

Docker网桥是宿主机虚拟出来的，并不是真实存在的网络设备，外部网络是无法寻址到的，这也意味着外部网络无法通过直接Container-IP访问到容器。如果容器希望外部访问能够访问到，可以通过映射容器端口到宿主主机（端口映射），即docker run创建容器时候通过 -p 或 -P 参数来启用，访问容器的时候就通过 [宿主机IP]:[容器端口] 访问容器。

四类网络模式
------

|Docker网络模式|配置|说明|
|:----|:----|:-----|:-----|
|host模式 |–net=host | 容器和宿主机共享Network namespace。|
| container模式|–net=container:NAME\_or\_ID |容器和另外一个容器共享Network namespace。 kubernetes中的pod就是多个容器共享一个Network namespace。|
| none模式| –net=none|容器有独立的Network namespace，但并没有对其进行任何网络设置，如分配veth pair 和网桥连接，配置IP等。|
| bridge模式 |–net=bridge| （默认为该模式）|

## host模式

如果启动容器的时候使用host模式，那么这个容器将不会获得一个独立的Network Namespace，而是和宿主机共用一个Network Namespace。容器将不会虚拟出自己的网卡，配置自己的IP等，而是使用宿主机的IP和端口。但是，容器的其他方面，如文件系统、进程列表等还是和宿主机隔离的。

使用host模式的容器可以直接使用宿主机的IP地址与外界通信，容器内部的服务端口也可以使用宿主机的端口，不需要进行NAT，host最大的优势就是网络性能比较好，但是docker host上已经使用的端口就不能再用了，网络的隔离性不好。

Host模式如下图所示：

![Host模式](https://tva1.sinaimg.cn/large/007S8ZIlly1gfgg856tr6j30je0foaar.jpg)

## container模式

这个模式指定新创建的容器和已经存在的一个容器共享一个 Network Namespace，而不是和宿主机共享。新创建的容器不会创建自己的网卡，配置自己的 IP，而是和一个指定的容器共享 IP、端口范围等。同样，两个容器除了网络方面，其他的如文件系统、进程列表等还是隔离的。两个容器的进程可以通过 lo 网卡设备通信。

Container模式示意图：

![Container网络模式](https://tva1.sinaimg.cn/large/007S8ZIlly1gfgg8goru4j30jb09b0tf.jpg)

## none模式

使用none模式，Docker容器拥有自己的Network Namespace，但是，并不为Docker容器进行任何网络配置。也就是说，这个Docker容器没有网卡、IP、路由等信息。需要我们自己为Docker容器添加网卡、配置IP等。

这种网络模式下容器只有lo回环网络，没有其他网卡。none模式可以在容器创建时通过--network=none来指定。这种类型的网络没有办法联网，封闭的网络能很好的保证容器的安全性。

None模式示意图:

![None网络模式](https://tva1.sinaimg.cn/large/007S8ZIlly1gfggiqb73ej30k309dt99.jpg)

## bridge模式

当Docker进程启动时，会在主机上创建一个名为docker0的虚拟网桥，此主机上启动的Docker容器会连接到这个虚拟网桥上。虚拟网桥的工作方式和物理交换机类似，这样主机上的所有容器就通过交换机连在了一个二层网络中。

从docker0子网中分配一个IP给容器使用，并设置docker0的IP地址为容器的默认网关。在主机上创建一对虚拟网卡veth pair设备，Docker将veth pair设备的一端放在新创建的容器中，并命名为eth0（容器的网卡），另一端放在主机中，以vethxxx这样类似的名字命名，并将这个网络设备加入到docker0网桥中。可以通过brctl show命令查看。

bridge模式是docker的**默认网络模式**，不写--net参数，就是bridge模式。使用docker run -p时，docker实际是在iptables做了DNAT规则，实现端口转发功能。可以使用iptables -t nat -vnL查看。

bridge模式如下图所示：

![Docker的网络实现](https://tva1.sinaimg.cn/large/007S8ZIlly1gfgg9qxdlgj30u30mbjtc.jpg)

# docker network 命令

```bash
$ docker network --help

Usage:	docker network COMMAND

Commands:
  connect     Connect a container to a network
  create      Create a network
  disconnect  Disconnect a container from a network
  inspect     Display detailed information on one or more networks
  ls          List networks
  prune       Remove all unused networks
  rm          Remove one or more networks

Run 'docker network COMMAND --help' for more information on a command.
```

## docker network ls|list （查看存在的网络）

使用 `ls` 命令查看存在的网络

```bash
$ docker network list
NETWORK ID          NAME                DRIVER              SCOPE
47ad7e772920        bridge              bridge              local
93effcf8b1ed        host                host                local
21449ae4b7ea        none                null                local
```

## docker network create （创建网络）

创建一个自己的网络，使用桥接模式：

```shell
$ docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 mynet
$ docker  network ls
NETWORK ID          NAME                DRIVER              SCOPE
47ad7e772920        bridge              bridge              local
93effcf8b1ed        host                host                local
c459df779378        mynet               bridge              local
21449ae4b7ea        none                null                local
```

使用`ls` 可以查看我们创建的网络`mynet`就已经存在了。其中：

* -driver bridge ：指定驱动器类型，默认为桥接（bridge）模式
* --subnet 192.168.0.0/16 ：指定网段
* --gateway 192.168.0.1 ：指定网关地址

创建自己的网络后，可以启动容器使用这个网络，然后可以看到这个容器就在你指定的网络里面了。

```shell
$ docker run -d -P --name tomcat02 --net mynet tomcat
$ docker run -d -P --name tomcat03 --net mynet tomcat
```

具体查看IP地址的命令可以使用`$ docker inspect`

使用自己网络启动的容器可以使用容器名来相互访问，这样就可以不用使用`--link`参数来连接亮两个容器来相互通过容器名称来相互访问：

```shell
$ docker exec -it tomcat02 ping tomcat03
PING tomcat03 (192.168.0.3) 56(84) bytes of data.
64 bytes from tomcat03.mynet (192.168.0.3): icmp_seq=1 ttl=64 time=0.157 ms
```

如果我们使用自己配置的网络来配置自己的服务就可以让不同的服务处于不同的网络环境下，这样就可以隔离不同的服务。

比如：我们可以创建一个redis的网络，把redis集群都放在这里面，可以创建一个mysql的网络，把mysql集群也放进来。

## docker network connect (把一个容器连接到某个网络)
如果我们分别创建两个网络，这两个网络是不同的子网中，分别是：

* `net01`: `192.168.0.0/16`
* `net02`: `192.169.0.0/16`

![两个子网，net01,net02](https://tva1.sinaimg.cn/large/007S8ZIlly1gfgmswaxlyj30gm09u0t5.jpg)

如图分别创建两个网络，**net01,net02**，然后在两个网络上启动两个tomcat容器，命令如下：

```shell
$ docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 net01
$ docker network create --driver bridge --subnet 192.169.0.0/16 --gateway 192.169.0.1 net02

$ docker run -d -P --name tomcat01 --net net01 tomcat
$ docker run -d -P --name tomcat02 --net net02 tomcat
```

创建好网络启动好容器后，可以在`tomcat01`和`tomcat02`中相互ping，可以发现并ping不通:

```shell
$ docker exec -it tomcat02 ping tomcat01
ping: tomcat01: Name or service not known

$ docker exec -it tomcat01 ping tomcat02
ping: tomcat02: Temporary failure in name resolution
```

如果我们要在tomcat01中能访问tomcat02就可以使用`$ docker network connect`命令，具体的用法可以使用：`$ docker network connect --help`来查看，使用如下命令就可以让tomcat01能访问tomcat02：

```shell
$ docker network connect net02 tomcat01

$ docker exec -it tomcat01 ping tomcat02
PING tomcat02 (192.169.0.2) 56(84) bytes of data.
64 bytes from tomcat02.net02 (192.169.0.2): icmp_seq=1 ttl=64 time=0.256 ms
64 bytes from tomcat02.net02 (192.169.0.2): icmp_seq=2 ttl=64 time=0.191 ms

$ ocker exec -it tomcat02 ping tomcat01
PING tomcat01 (192.169.0.3) 56(84) bytes of data.
64 bytes from tomcat01.net02 (192.169.0.3): icmp_seq=1 ttl=64 time=0.241 ms
64 bytes from tomcat01.net02 (192.169.0.3): icmp_seq=2 ttl=64 time=0.192 ms
```

查看`net02`的网络详情，可以知道是把容器：`tomcat01`加入到网络`net02`。

```shell
$ docker network inspect net02
...
"Containers": {
    "4e923271eb91eb898bc8e3833e4631059c2dd55d04766d40a38b4ee940bf7b74": {
        "Name": "tomcat02",
        "EndpointID": "dee904e428f4978eb5953932f875a9adf5864788cf495e72d496d36d62c916c9",
        "MacAddress": "02:42:c0:a9:00:02",
        "IPv4Address": "192.169.0.2/16",
        "IPv6Address": ""
    },
    "bc1d90d9fd6c38c181a304f8a769f4bf3287bb89ab3ff8c9f715d5e508900473": {
        "Name": "tomcat01",
        "EndpointID": "1b0cd9a050a3afe244eb97bc3c6a5136a50302c5acce45ccfa6116736c5de879",
        "MacAddress": "02:42:c0:a9:00:03",
        "IPv4Address": "192.169.0.3/16",
        "IPv6Address": ""
    }
},
...
```

