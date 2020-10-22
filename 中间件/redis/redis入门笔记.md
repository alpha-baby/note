# redis 入门笔记

[redis中文文档](http://redis.cn/commands.html)

[toc]

## string (字符串)

redis 是一个键值对的数据库，他的数据类型都是 key -> value 这样的类型。

就好比在`python`中的的`dict`类型，就好比`java`中的`hashmap类型`，和`Golang`中的`map`类型这种。

![](media/15550510808790/redis00001.png)

在`redis`的`sting`类型中value就是一个字符串。

### 重要 api


| api | 参数 | 功能 | 时间复杂度 |
| :-- | :-- | :-- | :-- |
| set | key value | 给一个key设置值 | O(1) |
| get | key  | 获取一个key的值 | O(1) |
| del | key | 删除一个key-value | O(1) |
| incr | key | key自增1 | O(1) |
| decr | key | key自减1 | O(1) |
| incryby | key k | key增加k | O(1) |
| decrby | key k | key自减1 | O(1) |
| mset | key value ... | 设置多个key-value | O(n) |
| mget | key ... | 获取多个值 | O(n) |
| getset | key newValue | 获取key对应的旧值并设置新的值为newValue | O(1) |
| append | key newValue | 将newValue追加到旧的值后面 | O(1) |
| strlen | key | 获取字符串的长度。 | O(1) |

### 实战

```
# 给键 "name:1" 设置一个值
127.0.0.1:6379> set name:1 xiaoming
OK
# 获取value
127.0.0.1:6379> get name:1
"xiaoming"
# 删除键值对
127.0.0.1:6379> del name:1
(integer) 1
# 验证键值对是否删除
127.0.0.1:6379> get name:1
(nil)
```

```
# 获取一个不错在的键值
127.0.0.1:6379> get test:counter
(nil)
# 给一个键值增加1
127.0.0.1:6379> incr test:counter
(integer) 1
# 获取一个计数器的值
127.0.0.1:6379> get test:counter
"1"
# 给一个键自增4
127.0.0.1:6379> incrby test:counter 4
(integer) 5
# 给一个键自减1
127.0.0.1:6379> decr test:counter
(integer) 4
# 获取键的值
127.0.0.1:6379> get test:counter
"4"
```

### TIPS

我们可以用字符串类型的数据结构应用在：
1. 缓存
2. 分布式锁
3. 计数器 (redis是单线程无竞争)


## hash (哈希)

### 特点

`redis` 的`hash`数据类型和`string`类型不同的是在value的部分，可以参考下图的结构。

![redis00002](media/15550510808790/redis00002.png)

其中在`value`中可以有多个`field`。
### hash重要的api

| api | 参数 | 功能 | 时间复杂度 |
| :-- | :-- | :-- | :-- |
| hget | key field | 获取key对应的哈希集中的field对应的value | O(1) |
| hmget | key field ... | hget的多操作 | O(n) |
| hset | key field value | 设置key指定的哈希集中指定字段的值。 | O(1) |
| hmset | key field ... | hset的多操作版本 | O(n) |
| hdel | key field [field ...] | 返回key对应哈希集中成功移除的field的数量 | O(n) |
| hexists | key field | 返回1则存在，0则不存在 | O(1) |
| hgetall | key | 返回key对应的所有field和value | O(n) |
| hkeys | key | 返回hash key对应的所有field | O(n) |
| hvals | key | 返回key对应的所有field的key | O(n) |
| hsetnx | key field value | 设置对应的field的value(如field已经存在，则失败) | O(1) |
| hincryby | key field intCounter | key对应的field的value自增intCounter | O(1) |
| hincrbyfloat | key field floatCounter | Hincrby 浮点版 | O(1) |

## list (列表)

### 特点
在value中是一个一个的元素组成的**有序的/元素可以重复的**列表

![](media/15550510808790/15550656223113.jpg)

从数据结构上来看，我们可以把`redis`中的`list`数据类型看成一个双向队列，我们可以在头和尾分别的`出队列`和`入队列`。

![](media/15550510808790/15550661623199.jpg)

我们还可以对`list`类型计算长度，删查某个索引的元素

### 重要的api


| api | 参数 | 功能 | 时间复杂度 |
| :-- | :-- | :-- | :-- |
| rpush | key value1 value2 ... | 从列表右端插入(1-N个)值。 | O(n) |
| lpush | Key value1 value2 ... | 从列表的左端插入(1-n)值。 | O(n) |
| linsert | Key before | after value newValue | 在指定的值前 |
| lpop | key | 从列表左边弹出一个item | O(1) |
| lrem | key count value | 根据count值，从列表中删除所有value相等的项。 | O(n) |
| ltrim | key start end | 按照索引范围修剪列表 | O(n) |
| llen | key | 获取队列的长度 | O(1) |
| lrange | key start end | 获取指定 | O(n) |
| lindex | key index | 获取列表指定索引的item | O(1) |
| lset | key index newValue | 设置列表指定索引值为newValue | O(1) |
| blpop | key [key …] timeout | 删除，并获得该列表中的第一元素，或阻塞，直到有一个可用,timeout是超时时间，为0这表示一直阻塞 |  |
| brpop | key [key …] timeout | blpop的反向版 |  |

### 实战

```
# 向key 为 "mylist" 的list中想右分别插入 "a", "b", "c"
127.0.0.1:6379> rpush mylist a b c
(integer) 3
# 遍历整个list
127.0.0.1:6379> lrange mylist 0 -1
1) "a"
2) "b"
3) "c"
# 从左边插入 "0"
127.0.0.1:6379> lpush mylist 0
(integer) 4
# 遍历整个list
127.0.0.1:6379> lrange mylist 0 -1
1) "0"
2) "a"
3) "b"
4) "c"
# 从右边取出一个元素
127.0.0.1:6379> rpop mylist
"c"
# 遍历整个list
127.0.0.1:6379> lrange mylist 0 -1
1) "0"
2) "a"
3) "b"
```

### TIPS

使用方法不是最重要的，因为这些api的使用方法我们在官方文档中都是可以查询到的，并且很详细，但是我们应该怎么使用，和吧redis应用在什么场景中才是最关键的。

1. LPUSH + LPOP = stack 栈
2. LPUSH + LPOP = queue 队列
3. LPUSH + LTRIM = capped collection 固定大小的集合
4. LPUSH + BRPOP = Message Queue 消息队列

## set (集合)

### 特点

`redis`的集合是**无序/不可重复**的，和列表一样，在执行插入和删除和判断是否存在某元素时，效率是很高的。集合最大的优势在于可以进行**交集并集差集**操作。

![](media/15550510808790/15553200178393.jpg)


### 重要的api

#### 1.集合内


| api | 参数 | 功能 | 时间复杂度 |
| :--- | :--- | :--- | :--- |
| sadd | key member [member ...] | 添加一个或者多个元素到集合(key)里,如果menber存在则插入失败  | O(n) |
| srem | key member [member ...] | 从集合里删除一个或多个元素 | O(n) |
| scard | key | 计算集合key中元素的个数 | O(1) |
| sismember | key member | 判断某个menber是否是集合中的元素 | O(1) |
| srandmember | key [count] | 从集合中随机取出count个元素 | O(1) |
| smember | key | 获取集合里面的所有元素 | O(1) |
| spop | key [count] | 随机取出count个元素并且删除这些元素 | O(1) |


#### 2.集合外


| api | 参数 | 功能时间 | 时间复杂度 |
| --- | --- | --- | :-- |
| sdiff | key key ... | 做差集 | O(n) |
| sinter | key key ... | 做交集 | O(n) |
| sunion | key key ... | 做并集 | O(n) |


### 实战

```
# 向集合 myset 中添加成员
127.0.0.1:6379> SADD myset "one"
(integer) 1
127.0.0.1:6379> SADD myset "two" "three"
(integer) 1
127.0.0.1:6379> smenber myset
(error) ERR unknown command `smenber`, with args beginning with: `myset`,
127.0.0.1:6379> smenbers myset
(error) ERR unknown command `smenbers`, with args beginning with: `myset`,
127.0.0.1:6379> smembers myset
1) "two"
2) "one"
3) "three"
127.0.0.1:6379> scard myset
(integer) 3
127.0.0.1:6379> spop myset
"three"
127.0.0.1:6379> sadd myset "four"
(integer) 1
127.0.0.1:6379> spop
(error) ERR wrong number of arguments for 'spop' command
127.0.0.1:6379> spop myset
"two"
```

### TPIS

SADD = Tagging 标签
SPOP/SRANDMEMBER = random item 随机场景
SADD + SINTER = Social Graph 社交

## sorted set (有序集合)

### 特点

 对比`set`
 
| 集合 | 有序 |
| --- | --- |
| 无重复元素 | 无重复元素 |
| 无序 | 有序 |
| element | element+socre |
 
对比`list`
 
| 列表 | 有序集合 |
| --- | --- |
| 有重复元素 | 无重复元素 |
| 有序 | 有序 |
| element | element+score |

`sorted set`的结构基本就如下图所示

![](media/15550510808790/15553349856704.jpg)


### 重要api


| api | 参数 | 功能 | 时间复杂度 |
| --- | --- | --- | --- |
| zadd | key score element ... | 向有序集合中添加一个或多个成员 | O(logN) |
| zrem | key element ... | 删除有序集合中的某个或多个成员 | O(n) |
| Zincrby | key increScore element | 增加或减少成员的分数 | O(1) |
| zcard | key | 计算有序集合中成员的个数 | O(1) |
| zrange | key start end [withscores] | 返回指定索引范围内的升序元素 | O(log(N)+m) |
| zrangebyscore | key minScore maxScore [withscore] | 返回指定分数范围内的升序元素结果 | O(log(N)+m) |
| zcount | key mixScore maxCount  | 返回分数范围内的成员数量 | O(log(N)+m) |
| zremrangebyrank | key start end | 在排序设置的所有成员在给定的索引中删除 | O(log(N)+m) |


### 实战

```
# 向有序集合中添加三个成员
127.0.0.1:6379> zadd name:score 70 lihua 89 zhangsan 88 xiaoming
(integer) 3
# 查询有序集合中某个成员的分数
127.0.0.1:6379> zscore name:score xiaoming
"88"
# 查询有序集合中成员的个数
127.0.0.1:6379> zcard name:score
(integer) 3
# 查询有序集合中成员的排名(分数的升序排名)
127.0.0.1:6379> zrank name:score xiaoming
(integer) 1
# 查询有序集合某段索引范围内的排名列表
127.0.0.1:6379> zrange name:score 0 -1 withscores
1) "lihua"
2) "70"
3) "xiaoming"
4) "88"
5) "zhangsan"
6) "89"
# 返回某个分数段内成员的数量
127.0.0.1:6379> zcount name:score 70 80
(integer) 1
```


> 主要是给自己学过的东西记录一下



