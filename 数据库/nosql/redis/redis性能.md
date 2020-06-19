# redis 性能

## 测试redis性能

redis自带了性能测试工具：`redis-benchmark`，其中有很多参数，参数如图所示：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gfhihtde9dj30n60h2q4m.jpg)

例如：测试100个并发连接 10W 请求，具体命令如下：

```bash
$ redis-benchmark -p 6379 -h localhost -c 100 -n 100000
...
====== SET ======
  100000 requests completed in 2.90 seconds
  100 parallel clients
  3 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  multi-thread: no

0.24% <= 1 milliseconds
71.47% <= 2 milliseconds
95.02% <= 3 milliseconds
98.18% <= 4 milliseconds
99.33% <= 5 milliseconds
99.75% <= 6 milliseconds
99.92% <= 7 milliseconds
99.98% <= 8 milliseconds
100.00% <= 8 milliseconds
34482.76 requests per second
...
```

如图看以上命令执行后得到的`set`指令的性能数据，得到的指标信息应该这样分析：

* 100000 requests completed in 2.90 seconds
    - 10W 个请求共花费了2.9秒
* 100 parallel clients
    - 100个并行的客户端
* 3 bytes payload
    - 每次请求的数据大小为3字节
* keep alive: 1
    - 这次测试的redis服务器只有一个
* 0.24% <= 1 milliseconds
    - 0.24%的请求处理时间在1毫秒以内
* 34482.76 requests per second
    - 每秒处理34482多个请求

