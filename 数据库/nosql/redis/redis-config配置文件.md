# redis config 配置文件

[toc]

在启动redis的时候可以配置文件来启动，启动命令如下：

```bash
$ redis-server /path/to/redis.conf
```

我们在使用`redis-cli`客户端工具的时候可以用如下命令来设置配置和查看配置：

```bash
127.0.0.1:6379> config get dbfilename
1) "dbfilename"
2) "dump.rdb"
127.0.0.1:6379> config get pidfile
1) "pidfile"
2) ""
127.0.0.1:6379> config get loglevel
1) "loglevel"
2) "notice"
127.0.0.1:6379> config get * # 获取所有的配置项
  1) "rdbchecksum"
  2) "yes"
  3) "daemonize"
  4) "no"
  ....
```

还可以使用`config set parameter value`来设置配置。

## network 配置

**bind**: 指定绑定的IP，如果要让其他的访问直接绑定`0.0.0.0`
**protected-mode**: 默认为yes，表示保护模式，如果要在服务器上安装好后在本地远程访问，就需要把这个设置为：`no`
**port**: 指redis-server监听的端口

## general 配置

**daemonize**：默认为no，表示以守护进程方式启动，也就是把进程放到后台去运行
**pidfile**: 如果以守护进程方式启动，name需要把进程的PID存放到文件中。
**loglevel**: 日志级别，默认为notice：还有：debug，verbose，warning
**database**: 默认值为：16，表示有16个数据库
**always-show-logo**: 默认为yes，指定的在启动redis-server的时候是否显示redis的logo

## SNAPSHOTTING 快照

**save**: 指定在多长时间内，有多少次更新操作，就将数据同步到数据文件，可以多个条件配合

默认配置为：

```bash
save 900 1
save 300 10
save 60 10000
#   满足以下条件将会同步数据:
#   900秒（15分钟）内有1个更改
#   300秒（5分钟）内有10个更改
#   60秒内有10000个更改
```

- **rdbcompression**: 指定存储至本地数据库时是否压缩数据，默认为yes，Redis采用LZF压缩，如果为了节省CPU时间，可以关闭该选项，但会导致数据库文件变的巨大
- **dbfilename**: 指定本地数据库文件名，默认值为dump.rdb
- **dir**: 指定本地数据库存放目录，文件名由上一个dbfilename配置项指定, 注意，这里只能指定一个目录，不能指定文件名
- **stop-writes-on-bgsave-error**: 持久化出错以后是否继续工作
- **rdbchecksum**：默认值是yes。在存储快照后，我们还可以让redis使用CRC64算法来进行数据校验，但是这样做会增加大约10%的性能消耗，如果希望获取到最大的性能提升，可以关闭此功能。

## REPLICATION 主从复制

- **slave-serve-stale-data**：默认值为yes。当一个 slave 与 master 失去联系，或者复制正在进行的时候，slave 可能会有两种表现：
    - 1) 如果为 yes ，slave 仍然会应答客户端请求，但返回的数据可能是过时，或者数据可能是空的在第一次同步的时候 
    - 2) 如果为 no ，在你执行除了 info he salveof 之外的其他命令时，slave 都将返回一个 "SYNC with master in progress" 的错误
- **slave-read-only**：配置Redis的Slave实例是否接受写操作，即Slave是否为只读Redis。默认值为yes。
- **repl-diskless-sync**：主从数据复制是否使用无硬盘复制功能。默认值为no。
- **repl-diskless-sync-delay**：当启用无硬盘备份，服务器等待一段时间后才会通过套接字向从站传送RDB文件，这个等待时间是可配置的。  这一点很重要，因为一旦传送开始，就不可能再为一个新到达的从站服务。从站则要排队等待下一次RDB传送。因此服务器等待一段  时间以期更多的从站到达。延迟时间以秒为单位，默认为5秒。要关掉这一功能，只需将它设置为0秒，传送会立即启动。默认值为5。
- **repl-disable-tcp-nodelay**：同步之后是否禁用从站上的TCP_NODELAY 如果你选择yes，redis会使用较少量的TCP包和带宽向从站发送数据。但这会导致在从站增加一点数据的延时。  Linux内核默认配置情况下最多40毫秒的延时。如果选择no，从站的数据延时不会那么多，但备份需要的带宽相对较多。默认情况下我们将潜在因素优化，但在高负载情况下或者在主从站都跳的情况下，把它切换为yes是个好主意。默认值为no。

## SECURITY 安全

**rename-command**：命令重命名，对于一些危险命令例如：
  - flushdb（清空数据库）
  - flushall（清空所有记录）
  - config（客户端连接后可配置服务器）
  - keys（客户端连接后可查看所有存在的键）                   

　　作为服务端redis-server，常常需要禁用以上命令来使得服务器更加安全，禁用的具体做法是是：`> rename-command FLUSHALL ""`
也可以保留命令但是不能轻易使用，重命名这个命令即可：
`> rename-command FLUSHALL abcdefg`
　　这样，重启服务器后则需要使用新命令来执行操作，否则服务器会报错unknown command。

**requirepass**:设置redis连接密码,比如: requirepass 123  表示redis的连接密码为123.

```bash
127.0.0.1:6379> config set requirepass "123456"
OK
127.0.0.1:6379> config get requirepass
1) "requirepass"
2) "123456"
```

## CLIENTS 客户端

**maxclients**：设置客户端最大并发连接数，默认无限制，Redis可以同时打开的客户端连接数为Redis进程可以打开的最大文件。  描述符数-32（redis server自身会使用一些），如果设置 maxclients为0 。表示不作限制。当客户端连接数到达限制时，Redis会关闭新的连接并向客户端返回max number of clients reached错误信息

## MEMORY MANAGEMENT 内存管理

**maxmemory**：设置Redis的最大内存，如果设置为0 。表示不作限制。通常是配合下面介绍的maxmemory-policy参数一起使用。
**maxmemory-policy**：当内存使用达到maxmemory设置的最大值时，redis使用的内存清除策略。有以下几种可以选择：
  - **volatile-lru**   利用LRU算法移除设置过过期时间的key (LRU:最近使用 Least Recently Used ) 
  - **allkeys-lru**   利用LRU算法移除任何key 
  - **volatile-random** 移除设置过过期时间的随机key 
  - **allkeys-random**  移除随机ke
  - **volatile-ttl**   移除即将过期的key(minor TTL) 
  - **noeviction**  不移除任何key，只是返回一个写错误 ，默认选项
**maxmemory-samples**：LRU 和 minimal TTL 算法都不是精准的算法，但是相对精确的算法(为了节省内存)。随意你可以选择样本大小进行检，redis默认选择3个样本进行检测，你可以通过maxmemory-samples进行设置样本数。

## APPEND ONLY MODE aof配置

**appendonly**：默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了。但是redis如果中途宕机，会导致可能有几分钟的数据丢失，根据save来策略进行持久化，Append Only File是另一种持久化方式，  可以提供更好的持久化特性。Redis会把每次写入的数据在接收后都写入appendonly.aof文件，每次启动时Redis都会先把这个文件的数据读入内存里，先忽略RDB文件。默认值为no。

**appendfilename**：aof文件名，默认是"appendonly.aof"

**appendfsync**：aof持久化策略的配置；no表示不执行fsync，由操作系统保证数据同步到磁盘，速度最快；always表示每次写入都执行fsync，以保证数据同步到磁盘；everysec表示每秒执行一次fsync，可能会导致丢失这1s数据

**no-appendfsync-on-rewrite**：在aof重写或者写入rdb文件的时候，会执行大量IO，此时对于everysec和always的aof模式来说，执行fsync会造成阻塞过长时间，no-appendfsync-on-rewrite字段设置为默认设置为no。如果对延迟要求很高的应用，这个字段可以设置为yes，否则还是设置为no，这样对持久化特性来说这是更安全的选择。   设置为yes表示rewrite期间对新写操作不fsync,暂时存在内存中,等rewrite完成后再写入，默认为no，建议yes。Linux的默认fsync策略是30秒。可能丢失30秒数据。默认值为no。

**auto-aof-rewrite-percentage**：默认值为100。aof自动重写配置，当目前aof文件大小超过上一次重写的aof文件大小的百分之多少进行重写，即当aof文件增长到一定大小的时候，Redis能够调用bgrewriteaof对日志文件进行重写。当前AOF文件大小是上次日志重写得到AOF文件大小的二倍（设置为100）时，自动启动新的日志重写过程。

**auto-aof-rewrite-min-size**：64mb。设置允许重写的最小aof文件大小，避免了达到约定百分比但尺寸仍然很小的情况还要重写。

**aof-load-truncated**：aof文件可能在尾部是不完整的，当redis启动的时候，aof文件的数据被载入内存。重启可能发生在redis所在的主机操作系统宕机后，尤其在ext4文件系统没有加上data=ordered选项，出现这种现象  redis宕机或者异常终止不会造成尾部不完整现象，可以选择让redis退出，或者导入尽可能多的数据。如果选择的是yes，当截断的aof文件被导入的时候，会自动发布一个log给客户端然后load。如果是no，用户必须手动redis-check-aof修复AOF文件才可以。默认值为 yes。

## LUA SCRIPTING 脚本

**lua-time-limit**：一个lua脚本执行的最大时间，单位为ms。默认值为5000.

## REDIS CLUSTER 集群

**cluster-enabled**：集群开关，默认是不开启集群模式。

**cluster-config-file**：集群配置文件的名称，每个节点都有一个集群相关的配置文件，持久化保存集群的信息。 这个文件并不需要手动配置，这个配置文件有Redis生成并更新，每个Redis集群节点需要一个单独的配置文件。请确保与实例运行的系统中配置文件名称不冲突。默认配置为nodes-6379.conf。

**cluster-node-timeout**：可以配置值为15000。节点互连超时的阀值，集群节点超时毫秒数

**cluster-slave-validity-factor**：可以配置值为10。在进行故障转移的时候，全部slave都会请求申请为master，但是有些slave可能与master断开连接一段时间了，  导致数据过于陈旧，这样的slave不应该被提升为master。该参数就是用来判断slave节点与master断线的时间是否过长。判断方法是：比较slave断开连接的时间和(node-timeout * slave-validity-factor) + repl-ping-slave-period     如果节点超时时间为三十秒, 并且slave-validity-factor为10,假设默认的repl-ping-slave-period是10秒，即如果超过310秒slave将不会尝试进行故障转移

**cluster-migration-barrier**：可以配置值为1。master的slave数量大于该值，slave才能迁移到其他孤立master上，如这个参数若被设为2，那么只有当一个主节点拥有2 个可工作的从节点时，它的一个从节点会尝试迁移。

**cluster-require-full-coverage**：默认情况下，集群全部的slot有节点负责，集群状态才为ok，才能提供服务。  设置为no，可以在slot没有全部分配的时候提供服务。不建议打开该配置，这样会造成分区的时候，小分区的master一直在接受写请求，而造成很长时间数据不一致。

> 参考 https://www.cnblogs.com/ysocean/p/9074787.html