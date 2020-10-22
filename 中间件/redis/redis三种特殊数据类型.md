# redis的三种特殊数据类型
 
## geospatial 地理位置

地址位置主要值得是经度和纬度， 通过经度和纬度可以计算两个位置的距离等。 

有关Geo数据结构的操作命令有如下六个：

1. GEOADD
2. GEODIST
3. GEOHASH
4. GEOPOS
5. GEORADIUS
6. GEORADIUSBYMEMBER

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfjngd1lnwj30oy094js8.jpg)

可以参考中文官网的解释：http://redis.cn/commands.html#geo

###  GEOADD 

添加地理位置：

```bash
127.0.0.1:6379> geoadd china:city 116.23128 40.22077 beijing
(integer) 1
127.0.0.1:6379> geoadd china:city 113.6401 34.72468 zhengzhou
(integer) 1
127.0.0.1:6379> geoadd china:city 121.48941 31.40527 shanghai
(integer) 1
127.0.0.1:6379> geoadd china:city 104.10194 30.65984 chengdu
(integer) 1
127.0.0.1:6379> geoadd china:city 108.93425 34.23053 xian
(integer) 1
```

### GEOPOS

获取某个地方的具体经纬度，例如获取北京的经纬度：

```bash
127.0.0.1:6379> geopos china:city beijing #获取北京的经纬度
1) 1) "116.23128265142440796"
   2) "40.22076905438526495"
127.0.0.1:6379> geopos china:city beijing xian # 获取北京和西安的经纬度
1) 1) "116.23128265142440796"
   2) "40.22076905438526495"
2) 1) "108.93425256013870239"
   2) "34.23053097599082406"
```

### GEODIST

计算两地的距离，例如计算北京到先得距离：

```bash
127.0.0.1:6379> geodist china:city beijing xian km
"927.5371"
```

GEODIST 命令返回的距离可以有不同的单位，上述例子中使用的单位是千米，更多的记录单位如下：

* `m` 表示单位为米。
* `km` 表示单位为千米。
* `mi` 表示单位为英里。
* `ft` 表示单位为英尺。

### GEORADIUS

以给定的经纬度为中心， 返回键包含的位置元素当中， 与中心的距离不超过给定最大距离的所有位置元素。

```bash
# georadius china:city 108 30 500 m|km|ft|mi [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count] [ASC|DESC] [STORE key]
127.0.0.1:6379> georadius china:city 104.10194 30.65984 1000 km
1) "chengdu"
2) "xian"
127.0.0.1:6379> georadius china:city 104.10194 30.65984 1000 km withdist withcoord
1) 1) "chengdu"
   2) "0.0002"
   3) 1) "104.10194188356399536"
      2) "30.65983886217613019"
2) 1) "xian"
   2) "602.7324"
   3) 1) "108.93425256013870239"
      2) "34.23053097599082406"
```

在给定以下可选项时， 命令会返回额外的信息：

* `WITHDIST`: 在返回位置元素的同时， 将位置元素与中心之间的距离也一并返回。 距离的单位和用户给定的范围单位保持一致。
* `WITHCOORD`: 将位置元素的经度和维度也一并返回。
* `WITHHASH`: 以 52 位有符号整数的形式， 返回位置元素经过原始 geohash 编码的有序集合分值。 这个选项主要用于底层应用或者调试， 实际中的作用并不大。

命令默认返回未排序的位置元素。 通过以下两个参数， 用户可以指定被返回位置元素的排序方式：

* `ASC`: 根据中心的位置， 按照从近到远的方式返回位置元素。
* `DESC`: 根据中心的位置， 按照从远到近的方式返回位置元素。

在默认情况下， `GEORADIUS` 命令会返回所有匹配的位置元素。 虽然用户可以使用 COUNT <count> 选项去获取前 N 个匹配元素， 但是因为命令在内部可能会需要对所有被匹配的元素进行处理， 所以在对一个非常大的区域进行搜索时， 即使只使用 COUNT 选项去获取少量元素， 命令的执行速度也可能会非常慢。 但是从另一方面来说， 使用 COUNT 选项去减少需要返回的元素数量， 对于减少带宽来说仍然是非常有用的。

### GEORADIUSBYMEMBER

这个命令和 GEORADIUS 命令一样， 都可以找出位于指定范围内的元素， 但是 GEORADIUSBYMEMBER 的中心点是由给定的位置元素决定的， 而不是像 GEORADIUS 那样， 使用输入的经度和纬度来决定中心点

指定成员的位置被用作查询的中心。

```bash
127.0.0.1:6379> georadiusbymember china:city chengdu 500 km
1) "chengdu"
```

### GEOHASH

返回一个或多个位置元素的 Geohash 表示。

通常使用表示位置的元素使用不同的技术，使用Geohash位置52点整数编码。由于编码和解码过程中所使用的初始最小和最大坐标不同，编码的编码也不同于标准。此命令返回一个标准的Geohash，在维基百科和geohash.org网站都有相关描述。

```bash
127.0.0.1:6379> geohash china:city beijing
1) "wx4sucvncn0"
```

### ZSET

geo数据结构本质就是zset，所以zset的命令也可以用于geo数据结构：

```bash
127.0.0.1:6379> zrem china:city beijing # 删除北京
(integer) 1
127.0.0.1:6379> zrange china:city 0 -1 # 遍历所有的城市
1) "chengdu"
2) "xian"
3) "shanghai"
4) "zhengzhou"
```

## Hyperloglog

redis 的Hyperloglog数据结构是用来做基数统计的，可以用到例如这样的场景中：统计一个站点的访问人数(同一个人访问多次只计算一次)，计算的结果是有0.8%的误差的。

```bash
127.0.0.1:6379> pfadd myset one two three four five six
(integer) 1
127.0.0.1:6379> pfcount myset # 统计集合中不同元素的舒朗
(integer) 6
127.0.0.1:6379> pfadd myset-two four seven eight ten one
(integer) 1
127.0.0.1:6379> pfmerge myset-3 myset myset-two # 合并后两个集合为第一个集合
OK
127.0.0.1:6379> pfcount myset
(integer) 6
127.0.0.1:6379> pfcount myset-two
(integer) 5
127.0.0.1:6379> pfcount myset-3 # 得到合并后的结果
(integer) 9
```

## Bigmaps

bitmaps: 中文叫做位图，用二进制位来存储信息，每个位要么是0或者1，例如用来统计用户信息，活跃或者不活跃！登陆、未登录！打卡，365天，例如我存储七天的数据：

```bash
127.0.0.1:6379> setbit week 0 0
(integer) 0
127.0.0.1:6379> setbit week 1 0
(integer) 0
127.0.0.1:6379> setbit week 2 1
(integer) 0
127.0.0.1:6379> setbit week 3 0
(integer) 0
127.0.0.1:6379> setbit week 4 1
(integer) 0
127.0.0.1:6379> setbit week 5 0
(integer) 0
127.0.0.1:6379> setbit week 6 0
(integer) 0
```

获取每位的记录：

```bash
127.0.0.1:6379> getbit week 0
(integer) 0
127.0.0.1:6379> getbit week 2
(integer) 1
```

查看有多少位为1：

```bash
127.0.0.1:6379> bitcount week 0 -1
(integer) 2
```