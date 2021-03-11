# redis各种模式

> 此文提到的go-redis源码版本是 v8.7.1

如果对`NoSQL`数据库进行简单分类，`redis`可以分类为`键值(key-value)`类型的数据库。

`redis` 分类:

1. 单机模式
2. 主从模式
3. 哨兵模式
4. 集群模式

# 1. 单机模式

单实例就不赘述。

# 2. 主从模式

![redis 主从模式](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/03-11-eOZqhY.png)

我们为什么需要使用redis的主从模式呢？在高并发的场景中，如果我们对单机的redis进行读写肯定是不够的。所以需要使用redis的主从模式，把主节点的数据不断同步到从节点中，从节点相当于是主节点的一个备份，然后所有的写操作都到主节点上操作，所有的读操作可以到主节点或者从节点上，也就是我们所谓的：**主从复制、读写分离**。

主从模式有个缺点是：主节点只有一个，如果写数据的量大了，把主节点搞挂了，那么就不能写数据库。也可以手动的把某台从机器设置为主，然后其他的从机连接到这个新的主，再从新的主上重新同步数据。

# 3. 哨兵模式

在主从模式的基础上，衍生出了哨兵模式。

主从切换技术的方法是:当主服务器宕机后，需要手动把一台从服务器切换为主服务器，这就需要人工干预，费事费力，还会造成一段长时间内服务不可用。这不是一种推荐的方式，更多时候，我们优先考虑`哨兵模式`。Redis从2.8开始正式提供了Sentinel(哨兵) 架构来解决这个问题。

每个哨兵能够后台监控每个redis实例是否故障，如果故障了根据投票数自动将从库转换为主库。 哨兵模式是一种特殊的模式，首先Redis提供了哨兵的命令，哨兵是一个独立的进程，作为进程，它会独立运行。其原理是哨兵通过发送命令，等待Redis服务器响应，从而监控运行的多个Redis实例。

![redis哨兵模式](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/03-11-a0mLbi.png)

这里我们部署的哨兵可以是多个也可以是一个，我们怎么去使用redis的哨兵集群呢？接下来我们一golang的一个redis客户端[`go-redis`](https://github.com/go-redis/redis)为例来介绍下：

> 首先说明下我部署的redis的情况: 一主二从 三个哨兵
> 我使用的是 helm bitnami/redis
> 如果你也要使用这个chart来安装redis哨兵模式可以先添加如下的chart仓库
> helm repo add bitnami https://charts.bitnami.com/bitnami

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/go-redis/redis/v8"
)

func main() {
    // 新建自动故障转移客户端
    cli := redis.NewFailoverClient(&redis.FailoverOptions{
        MasterName:       "mymaster",
        Password:         "123456",
        SentinelPassword: "123456",
        SentinelAddrs:    []string{"localhost:30002"},
    })

    resoult := cli.Get(context.TODO(), "name")
    if resoult.Err() != nil {
        log.Fatalf("error: %v\n", resoult.Err())
    }
    name := resoult.Val()
    defer cli.Close()

    fmt.Printf("redis get name: %v\n", name)
}
```

以上demo代码可以看出来我们只配置了其中一个哨兵的地址，但是我在前面说明了下我测试的环境部署了三个哨兵。其实在`go-redis`这个开源库里面会自动的去拉取其他哨兵的地址。

例如我们可以使用`redis-cli`命令行工具去拉取下其他哨兵的地址：

```bash
> sentinel sentinels mymaster
1)  1) "name"
    2) "803cead26d90952294dc14549275fbb0496d5237"
    3) "ip"
    4) "10.244.0.35"
    5) "port"
    6) "26379"
    7) "runid"
    8) "803cead26d90952294dc14549275fbb0496d5237"
    9) "flags"
   10) "sentinel"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "15"
   19) "last-ping-reply"
   20) "15"
   21) "down-after-milliseconds"
   22) "60000"
   23) "last-hello-message"
   24) "1388"
   25) "voted-leader"
   26) "?"
   27) "voted-leader-epoch"
   28) "0"
2)  1) "name"
    2) "3d7f37c64d9ecc0087227048eab10bc14dbf1be8"
  # ....
   28) "0"
```

没有哨兵都要和主从的每个redis实例进行通信，所有每个哨兵都知道所有的redis实例的地址，虽然我们在以上demo代码中没有具体配置redis实例的地址，其实内部是通过哨兵来获取的，并且哨兵会给出那个实例是主哪些是从，我们也可以用`redis-cli`来尝试获取。

```bash
todo
```

**以上demo代码新建的客户端是怎样故障切换的呢？**

`FailoverClient`内部其实封装了一个`SentinelClient`，一个`SentinelClient`你可以把它看作是一个和某个哨兵建立了连接的客户端，`SentinelClient`会去订阅一个消息，这个消息就是告诉所有正在使用redis的客户端主已经切换了，那么所有收到此消息的客户端就能自动的故障转移了。

具体的代码在：https://github.com/go-redis/redis/blob/v8.7.1/sentinel.go#L690

我在读`go-redis`源码的时候就发现一个问题，可参考此[github issue](https://github.com/go-redis/redis/issues/1091)。问题具体内容如下：

如果某个哨兵故障了，就应该切换另一个哨兵，但是`go-redis`这个库并没有实现这个逻辑。虽然源码里面获取了其他哨兵的地址，但是并没有用到，而且在解析其他哨兵地址的时候有问题，并没有正确解析。在以上给出的这issue中也可以看出这个问题很久以前就别别人发现了。但是一直都没有处理。

# 4. 集群模式

redis有五大基础类型，但是存储的时候我们都要指定一个`key`，我们可以对这个key计算一个hash值，我看在`go-redis`里面使用的[`crc16`](https://github.com/go-redis/redis/blob/b965d69fc9defa439a46d8178b60fc1d44f8fe29/internal/hashtag/hashtag.go#L73)。

先来大概了解下集群模式的架构：

![redis集群模式](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/03-11-8GbDnT.png)

还是以如下demo代码为例，我们来分析`go-redis`是怎么使用redis集群的：

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/go-redis/redis/v8"
)

func main() {
    cli := redis.NewClusterClient(&redis.ClusterOptions{
        Addrs: []string{"10.244.0.30:6379"},
    })

    resoult := cli.Get(context.TODO(), "_name")
    if resoult.Err() != nil {
        log.Fatalf("error: %v\n", resoult.Err())
    }
    name := resoult.Val()
    defer cli.Close()

    fmt.Printf("redis get name: %v\n", name)
}
```

以上代码中我们虽然只指定了一个实例的地址但是和哨兵模式一样，客户端都会自动获取所有实例的地址。我们可以用`redis-cli`尝试获取整个集群的所有实例的地址：

```bash
10.244.0.30:6379> cluster  slots
1) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "10.244.0.30" # 默认第一个是主，其他是从
      2) (integer) 6379
      3) "ccf7eb9fec16b15c18e597b4340462e6885c2856"
   4) 1) "10.244.0.24"
      2) (integer) 6379
      3) "210de945d1b21e6a6c431d49dc765d8cece2997c"
2) 1) (integer) 0
   2) (integer) 5460
   3) 1) "10.244.0.29"
      2) (integer) 6379
      3) "4ec0e709abca57f5a02f8d31b8130742dc91a108"
   4) 1) "10.244.0.25"
      2) (integer) 6379
      3) "d03c2e0d199f2f10953557077a408743e0221020"
3) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "10.244.0.28"
      2) (integer) 6379
      3) "0adf75f8368852247f429df8f1f33af22aef6c42"
   4) 1) "10.244.0.26"
      2) (integer) 6379
      3) "53295dc3d811e2dd76abe2455eb37997d8dabdd5"
```

可以知道redis返回了这个拓扑结构我们可以尝试使用`redis-cli`get下`_name`的值：

```bash
10.244.0.30:6379> get _name
-> Redirected to slot [9837] located at 10.244.0.28:6379
"123"
10.244.0.28:6379>
```

`redis-cli`会自动计算"_name"的哈希值为[9837]，找到此槽位对应的redis实例，然后切换连接到此实力上，然后在此实例上再执行get操作。

在`go-redis`源码中这里进行计算key的槽位：https://github.com/go-redis/redis/blob/v8.7.1/cluster.go#L759
这里取到此槽位对应的redis实例：https://github.com/go-redis/redis/blob/v8.7.1/cluster.go#L773

我们如果仔细探寻源码可以发现，`go-redis`还提供了了客户端：`FailoverClusterClient`,我们可以大胆的猜测，redis的集群模式也可以加哨兵，如果某个主挂掉了哨兵可以自动的切换主。

我们可以用哨兵命令查看监控的主：

```bash
> sentinel masters
1)  1) "name"
    2) "mymaster"
    3) "ip"
    4) "10.244.0.33"
    5) "port"
    6) "6379"
    7) "runid"
    8) "0e9ea3f12df2d9af7e60deb15a555d22d4ea8775"
    9) "flags"
   10) "master"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "767"
   19) "last-ping-reply"
   20) "767"
   21) "down-after-milliseconds"
   22) "60000"
   23) "info-refresh"
   24) "5263"
   25) "role-reported"
   26) "master"
   27) "role-reported-time"
   28) "467224"
   29) "config-epoch"
   30) "0"
   31) "num-slaves"
   32) "2"
   33) "num-other-sentinels"
   34) "2"
   35) "quorum"
   36) "2"
   37) "failover-timeout"
   38) "18000"
   39) "parallel-syncs"
   40) "1"
```

所以哨兵是可以监控多个主-从集群的，在redis集群模式中也可以用哨兵来进行自动化运维。