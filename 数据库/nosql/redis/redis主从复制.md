# redis 主从复制

**概念**：

主从复制是指将一台redis服务器的数据复制到其他的redis服务器中。前者称为主节点(master/leader)，后者称为从节点(slave/follower)；数据的复制是单向的，只能由主节点到从节点，Master节点以写为主，Slave以读为主。

默认情况下，每台redis服务器都是主节点，且一个主节点可以有多个从节点（或者没有从节点），但一个从节点只能由一个主节点。

主从复制的作用主要包括：

1. 数据冗余：主从复制实现了数据的热备份，是持久化之外的一种数据冗余方式。
2. 故障恢复：当主节点出现问题时，可以由从节点提供服务，实现快速的故障恢复；实际上是一种服务的冗余。
3. 负载均衡：在主从复制的基础上，配合读写分离，可以由主节点提供写服务，由从节点提供读服务（即写redis数据时应连接主节点，读redis数据时应连接从节点），分担服务器负载；尤其在写少读多的场景下，通过多个节点分担读负载，可以大大提高redis服务器的并发。
4. 高可用基石：除了上述作用以外，主从复制还是哨兵和集群能够实施的基础，因此说主从复制是redis高可用的基础。

一般来说，要从redis运用于工程项目中，只使用一台redis是万万不能的，原因如下：

1. 从结构上，单个redis服务器会发生单点故障，并且一台服务器需要处理所有的请求负载，压力较大。
2. 从容量上，单个redis服务器内存容量有限，就算一台redis服务器内存为256GB，也不能将所有内存用作redis存储内存，一般来说，单台redis最大使用内存不应该超过20G。

## 配置主从环境

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfphg74ukdj30wn0ko130.jpg)

一把来说redis的主从模式基本上都是要1主2从以上，这里我们按照上图中的结构，使用docker来配置一主三从。

我们可以用命令来查看redis的主从复制中某个节点的信息:

```bash
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:0
master_replid:c84747a8c71491dace6a558d91c548aad6b51382
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

### 在docker中创建自己的网络

```bash
$ docker network create --driver bridge --subnet 192.170.0.0/16 --gateway 192.170.0.1 redis-network
```

然后查看下是否创建成功：

```bash
$ docker network lsNETWORK ID          NAME                DRIVER              SCOPE
40b93119bc65        bridge              bridge              local
93effcf8b1ed        host                host                local
21449ae4b7ea        none                null                local
0cb8f3e0a1e3        redis-network       bridge              local
```

### 启动4个redis重启

```bash
$ docker run --name redis-master -d -p 6379:6379 --net=redis-network redis
$ docker run --name redis-slave1 -d -p 6381:6379 --net=redis-network redis
$ docker run --name redis-slave2 -d -p 6382:6379 --net=redis-network redis
$ docker run --name redis-slave3 -d -p 6383:6379 --net=redis-network redis
```

然后容器的运行情况：

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
a699de42f64e        redis               "docker-entrypoint.s…"   8 minutes ago       Up 8 minutes        0.0.0.0:6383->6379/tcp   redis-slave3
7e60db76fc7b        redis               "docker-entrypoint.s…"   9 minutes ago       Up 9 minutes        0.0.0.0:6382->6379/tcp   redis-slave2
e96735264a27        redis               "docker-entrypoint.s…"   46 minutes ago      Up 46 minutes       0.0.0.0:6379->6379/tcp   redis-master
9752cb53bc07        redis               "docker-entrypoint.s…"   47 minutes ago      Up 47 minutes       0.0.0.0:6381->6379/tcp   redis-slave1
```

### 把从机连接上主机

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfpl6enk3hj310i0f7aut.jpg)

如上图，左边是主机，右边三个是从机，在从机中都执行如下命令，然后就可以连接上主机：

```bash
127.0.0.1:6379 > slaveof redis-master 6379
```

然后在主机中执行`> info replication`就可以看到主机上连接了三个从机，然后我们测试下在主机上写入数据然后在从机上读取数据，看是否同步：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfplgcbm80j30s40f1dua.jpg)

从图中可以看到数据是可以正常同步的，所以配置是成功的。

### 节点选举

如果主节点意外崩溃了，从节点是不会自动变成主机的，我们可以手动的指定某个从机变成主机，命令是：`> slaveof no one`。

如果我们需要当主机宕机后会自动的重新选举一个新的主节点，我们可以配置哨兵模式来自动选举。

哨兵模式是主从切换的一种技术方法，当主服务器宕机后会自动选举新的主机节点，redis2.8之后正式提供了Sentinel（哨兵）架构，在哨兵模式中后台会监控主机是否故障，如果发生了故障会根据投票数自动将从节点转为主节点。

哨兵模式是一种特殊的模式，首先Redis提供了哨兵的命令，哨兵是一个独立的进程，作为进程，它会独立运行。其原理是**哨兵通过发送命令，等待redis服务器的响应，从而监控运行多个redis实例。**

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfsziex6vqj30io0evtal.jpg)

哨兵主要有两个作用：

* 通过发送命令让redis服务器返回监控其运行状态，包括主服务器和从服务器。
* 当哨兵检测到master宕机，会自动将slave切换成master，然后通过**发布订阅模式**通知其他的从服务器，修改配置文件，让它们切换为主机。

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfsziqk5rgj30ln0b540m.jpg)

如上图，假设主服务器宕机，哨兵1先检测到这个结果，系统并不会马上进行failover过程，仅仅是哨兵1主观的认为主服务器不可用，这个现象成为主观下线。当后面的哨兵也检测到主服务器不可用，并且数量达到一定值时，那么哨兵之间就会进行一次投票，投票的结果由一个哨兵发起，进行failover[故障转移]操作。 切换成功后，就会通过发布订阅模式，让各个哨兵把自己监控的从服务器实现切换主机，这个过程称为客观下线。

在**redis-slave1**docker容器中，启动一个哨兵：

```bash
$ echo "sentinel monitor mysentinel redis-master 6379 1" > sentinel.conf
$ redis-sentinel sentinel.conf
```

然后我们把主机停掉:

```bash
$ docker stop redis-master
```

然后我们会发现，在**redis-slave3**容器被选举成了主节点：

```bash
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:2
slave0:ip=192.170.0.3,port=6379,state=online,offset=43301,lag=0
slave1:ip=192.170.0.4,port=6379,state=online,offset=43301,lag=0
master_replid:c0cb66218b13778eaeb71b6d797bd7504187da2f
master_replid2:0d6f4017b9387c0cdb42aa9f2e24adfefdd75526
master_repl_offset:43301
second_repl_offset:38747
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:43301
```

然后重新启动容器：**redis-master**：

```bash
$ docker start redis-master
```

**redis-master**节点启动后自动的连接上了**redis-slave3**节点成为了从节点：

```bash
127.0.0.1:6379> info replication
# Replication
role:slave
master_host:192.170.0.5
master_port:6379
master_link_status:up
master_last_io_seconds_ago:2
master_sync_in_progress:0
slave_repl_offset:54251
slave_priority:100
slave_read_only:1
connected_slaves:0
master_replid:c0cb66218b13778eaeb71b6d797bd7504187da2f
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:54251
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:51532
repl_backlog_histlen:2720
```

**哨兵模式的优点**：

1. 哨兵集群，基于主从复制模式，所有的主从配置优点，它全有
2. 主从可以切换，故障可以转移，系统的可用性就会更好
3. 哨兵模式就是主从模式的升级，手动到自动，更加的健壮

**哨兵模式的缺点**：

1. Redis 不好在线扩容  ，集群容量一旦到达上限，在线扩容就十分麻烦! 
2. 实现哨兵模式的配置其实是很麻烦的，里面有很多选择!

**哨兵的所有配置文件**：

```ini
# Example sentinel.conf
# 哨兵sentinel实例运行的端口 默认26379
port 26379
# 哨兵sentinel的工作目录
dir /tmp
# 哨兵sentinel监控的redis主节点的 ip port
# master-name 可以自己命名的主节点名字 只能由字母A-z、数字0-9 、这三个字符".-_"组成。 # quorum 配置多少个sentinel哨兵统一认为master主节点失联 那么这时客观上认为主节点失联了 # sentinel monitor <master-name> <ip> <redis-port> <quorum>
sentinel monitor mymaster 127.0.0.1 6379 2
# 当在Redis实例中开启了requirepass foobared 授权密码 这样所有连接Redis实例的客户端都要提供 密码
# 设置哨兵sentinel 连接主从的密码 注意必须为主从设置一样的验证密码
# sentinel auth-pass <master-name> <password>
sentinel auth-pass mymaster MySUPER--secret-0123passw0rd
# 指定多少毫秒之后 主节点没有应答哨兵sentinel 此时 哨兵主观上认为主节点下线 默认30秒 # sentinel down-after-milliseconds <master-name> <milliseconds>
sentinel down-after-milliseconds mymaster 30000
# 这个配置项指定了在发生failover主备切换时最多可以有多少个slave同时对新的master进行 同步， 这个数字越小，完成failover所需的时间就越长，
但是如果这个数字越大，就意味着越 多的slave因为replication而不可用。
可以通过将这个值设为 1 来保证每次只有一个slave 处于不能处理命令请求的状态。
# sentinel parallel-syncs <master-name> <numslaves>
sentinel parallel-syncs mymaster 1
# 故障转移的超时时间 failover-timeout 可以用在以下这些方面:
#1. 同一个sentinel对同一个master两次failover之间的间隔时间。
#2. 当一个slave从一个错误的master那里同步数据开始计算时间。直到slave被纠正为向正确的master那 里同步数据时。
#3.当想要取消一个正在进行的failover所需要的时间。 #4.当进行failover时，配置所有slaves指向新的master所需的最大时间。不过，即使过了这个超时， slaves依然会被正确配置为指向master，但是就不按parallel-syncs所配置的规则来了
# 默认三分钟
# sentinel failover-timeout <master-name> <milliseconds>
sentinel failover-timeout mymaster 180000 # SCRIPTS EXECUTION
#配置当某一事件发生时所需要执行的脚本，可以通过脚本来通知管理员，例如当系统运行不正常时发邮件通知 相关人员。
#对于脚本的运行结果有以下规则: #若脚本执行后返回1，那么该脚本稍后将会被再次执行，重复次数目前默认为10 #若脚本执行后返回2，或者比2更高的一个返回值，脚本将不会重复执行。 #如果脚本在执行过程中由于收到系统中断信号被终止了，则同返回值为1时的行为相同。 #一个脚本的最大执行时间为60s，如果超过这个时间，脚本将会被一个SIGKILL信号终止，之后重新执行。
#通知型脚本:当sentinel有任何警告级别的事件发生时(比如说redis实例的主观失效和客观失效等等)， 将会去调用这个脚本，这时这个脚本应该通过邮件，SMS等方式去通知系统管理员关于系统不正常运行的信 息。调用该脚本时，将传给脚本两个参数，一个是事件的类型，一个是事件的描述。如果sentinel.conf配 置文件中配置了这个脚本路径，那么必须保证这个脚本存在于这个路径，并且是可执行的，否则sentinel无 法正常启动成功。
#通知脚本
# shell编程
# sentinel notification-script <master-name> <script-path> 
sentinel notification-script mymaster /var/redis/notify.sh

# 客户端重新配置主节点参数脚本
# 当一个master由于failover而发生改变时，这个脚本将会被调用，通知相关的客户端关于master地址已 经发生改变的信息。
# 以下参数将会在调用脚本时传给脚本:
# <master-name> <role> <state> <from-ip> <from-port> <to-ip> <to-port>
# 目前<state>总是“failover”,
# <role>是“leader”或者“observer”中的一个。
# 参数 from-ip, from-port, to-ip, to-port是用来和旧的master和新的master(即旧的slave)通 信的
# 这个脚本应该是通用的，能被多次调用，不是针对性的。
# sentinel client-reconfig-script <master-name> <script-path>
sentinel client-reconfig-script mymaster /var/redis/reconfig.sh # 一般都是由运维来配 置!
```


## 复制原理

slave启动后，当连接上master后会发送衣蛾sync命令，master街道命令，会启动后台的存盘进程，同时收集所有接收到的用于修改数据集命令，在后台进程执行完毕之后，master将传送整个数据文件到slave，并完成一次完全同步。

* **全量复制**：而slave服务在接收到数据库文件，将其存盘并加载到内存中。
* **增量复制**：master继续讲新的所有收集到的修改命令依次传给slave，完成同步。

如果从机断开后重新连接上master节点，全量复制将被自动执行。

