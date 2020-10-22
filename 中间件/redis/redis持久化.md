# redis 持久化 

redis 是基于内存的key-value数据库，但是我们在用redis存储一些比较重要的数据时就没有保障，如果redis的进程挂掉了，那么数据就丢失了，所以redis的持久化是非常重要的，持久化既不能影响性能，也要承担保证数据不能丢失的重要角色。

## RDB 持久化方式

RDB(Redis Database)在指定的时间间隔内将内存中的数据集快照写入磁盘，也就是Snapshot快照，它恢复也是将快照文件读到内存里。

Redis会单独创建(fork)一个子进程来进行持久化，会先将数据写入到一个临时文件中，待持久化过程都结束了，再用这个临时文件替换上次持久化好的文件。整个过程中，主进程是不进行任何IO操作。这就确保了极高的性能。如果需要进行大规模数据恢复，且对于数据恢复的完整性不是非常的敏感，那RDB方式要比AOF方式更加的高效。RDB的缺点是最后一次持久化后的数据可能丢失。redis默认就是使用的就是RDB方式来对数据进行持久化，所以不需要修改默认的配置文件。

默认配置文件中配置的RDB持久化后的文件名为：**dump.rdb**，其中可以通过配置文件中的**dbfilename**来配置持久化文件的文件名。

### 持久化规则配置

RDB的持久化规则是通过配置文件中的：**save**选项来配置，例如配置为：`save 60 5`意思是：如果在60秒内触发了5次修改就触发持久化一下，并且可以通过**save**选项可以配置多个规则。

```bash
# 时间策略
save 900 1
save 300 10
save 60 10000

# 文件名称
dbfilename dump.rdb

# 文件保存路径
dir /home/work/app/redis/data/

# 如果持久化出错，主进程是否停止写入
stop-writes-on-bgsave-error yes

# 是否压缩
rdbcompression yes

# 导入时是否检查
rdbchecksum yes
```

### RDB 持久化触发情况

自动触发有：
    - 根据我们的 `save m n` 配置规则自动触发；
    - 从节点全量复制时，主节点发送rdb文件给从节点完成复制操作，主节点会触发 `bgsave`；
    - 执行 `debug reload` 时；
    - 执行 `shutdown` 时，如果没有开启aof，也会触发。


针对RDB方式的持久化，手动触发可以使用：
    - `save`：会阻塞当前Redis服务器，直到持久化完成，线上应该禁止使用。
    - `bgsave`：该触发方式会fork一个子进程，由子进程负责持久化过程，因此阻塞只会发生在fork子进程的时候。

**bgsave**触发原理图：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfo476s8c3j30m80k7gmr.jpg)

这里注意的是 `fork` 操作会阻塞，导致Redis读写性能下降。我们可以控制单个Redis实例的最大内存，来尽可能降低Redis在fork时的事件消耗。以及上面提到的自动触发的频率减少fork次数，或者使用手动触发，根据自己的机制来完成持久化。

### 恢复RDB数据到redis中

只需要把RDB文件按照redis配置文件中：**dbfilename**和**dir**两个配置对应的地方，redis就会自动恢复文件中的持久化数据。 

同时你也可以使用redis-cli的命令：`> config get dbfilename`或者`> config get dir`来获取配置，当然也可以用`config set`指令来设置配置。

```bash
127.0.0.1:6379> config get dir
1) "dir"
2) "/data"
127.0.0.1:6379> config get dbfilename
1) "dbfilename"
2) "dump.rdb"
```

### 优缺点

**优点**：
    1. 适合大规模的数据恢复
    2. 对数据的完整性要求不高可以使用RDB模式

**缺点**：
    1. 需要一定的时间间隔进行操作，如果发生意外宕机可能会丢失当时的数据
    2. fork进程的时候，会占用一定的内存空间。

## AOF 持久化方式

AOF(Append Only File),记录每次对服务器写的操作,当服务器重启的时候会重新执行这些命令来恢复原始的数据。

## 配置文件

```bash
# 是否开启aof
appendonly yes

# 文件名称
appendfilename "appendonly.aof"

# 同步方式
appendfsync everysec

# aof重写期间是否同步
no-appendfsync-on-rewrite no

# 重写触发配置
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# 加载aof时如果有错如何处理
aof-load-truncated yes

# 文件重写策略
aof-rewrite-incremental-fsync yes
```

## AOF 持久化原理

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfo5su4nxtj30m80j23zw.jpg)

- 在重写期间，由于主进程依然在响应命令，为了保证最终备份的完整性；因此它依然会写入旧的AOF file中，如果重写失败，能够保证数据不丢失。
- 为了把重写期间响应的写入信息也写入到新的文件中，因此也会为子进程保留一个buf，防止新写的file丢失数据。
- 重写是直接把当前内存的数据生成对应命令，并不需要读取老的AOF文件进行分析、命令合并。
- AOF文件直接采用的文本协议，主要是兼容性好、追加方便、可读性高可认为修改修复。

## AOF 数据恢复

如果想要恢复AOF文件中的数据，方法和RDB持久化模式是一样的，把对应的文件放到正确的位置即可。如果在启动redis的时候发现AOF文件的格式被破坏了，那么可以用redis自带的工具：`redis-check-aof --fix`来修复文件。

数据恢复流程图：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfo5uba2z8j30if0m80tj.jpg)

## AOF 的优缺点

**优点**：
    1. 每次修改都同步，数据不容易丢失，完整性会更加好！
    2. 如果开启每秒都同步一次，可能会丢失一秒内的数据
    3. 不开启同步效率是最高的。

**缺点**：
    1. 对象RDB文件，AOF文件会占用更大的存储空空间。
    2. AOF运行效率也会比RDB慢。

> 参考 https://segmentfault.com/a/1190000015983518
