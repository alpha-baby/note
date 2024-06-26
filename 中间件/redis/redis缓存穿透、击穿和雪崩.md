# redis缓存穿透、击穿和雪崩

## 概念

### 缓存穿透（查不到）

在高并发下，查询一个不存在的值时，缓存不会被命中，导致大量请求直接落到持久层的数据库上，导致持久层的数据库系统压力过大，如活动系统里面查询一个不存在的活动。

### 缓存击穿（量太大，缓存突然过期）

缓存击穿和缓存穿透是不一样的，要区分开，是指一个key非常热点，在不停的扛着大并发，大并发集中对这一个点进行访问，当这个key在失效的瞬间，持续的大并发就穿破缓存，直接请求数据库。

### 缓存雪崩（缓存大面积失效）

当缓存服务器重启或者大量缓存集中在某一个时间段失效，这样在失效的时候，也会给后端系统(比如DB)带来很大压力。

## 解决方案

### redis高可用 

这个思想的含义是，既然redis有可能挂掉，那我多增设几台redis，这样一台挂掉之后其他的还可以继续
工作，其实就是搭建的集群。(异地多活!)

### 限流降级

这个解决方案的思想是，在缓存失效后，通过加锁或者队列来控制读数据库写缓存的线程数量。比如对
某个key只允许一个线程查询数据和写缓存，其他线程等待。

### 数据预热

数据加热的含义就是在正式部署之前，我先把可能的数据先预先访问一遍，这样部分可能大量访问的数 据就会加载到缓存中。在即将发生大并发访问前手动触发加载缓存不同的key，设置不同的过期时间，让 缓存失效的时间点尽量均匀。

> 参考 
> https://www.cnblogs.com/xichji/p/11286443.html
> https://www.jianshu.com/p/d00348a9eb3b