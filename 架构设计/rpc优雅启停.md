# rpc 优雅启停

什么是优雅启停？

优雅启动就是: 当我们启动服务后，流量就自动就打过来。
优雅停止就是：停止服务的时候，流量自动的断开，业务流量无损

## 利用反向代理

如果是启动，我们可以告诉反向代理服务器，然后把这个服务添加到反向代理的列表里面

如果是停止，我们可以先告诉反向代理服务器，把这个服务从代理列表删除，然后等到服务没有请求流量，也没有需要处理的请求后再停止进程

如果代理服务器是 nginx ，代理的服务是 http , 传统方式我们会发现这个过程都需要手动的修改 nginx 配置，很多地方都需要人工参与。

下文我们先消息讨论 http1.x 协议做么实现优雅的停止

## server 进行 fd 的迁移

可参考[MOSN 平滑升级原理解析](https://mosn.io/docs/concept/smooth-upgrade/)

此种方式比较硬核

## 利用协议让 client 主动断连

### HTTP1.x

我们先回顾一下一个 http 请求的过程：

![http1.x流程](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/11-08-0diV6o.png)

1. client 与 server 建立一个 tcp 连接
2. client 使用刚创建好的连接发送一个请求
3. server 收到这个请求后进行处理
4. server 返回一个响应给client

其中有个一个细节是，一个 tcp 同时能且只能处理一个请求+响应。

https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Connection

在 http1.1 中定义了一个用于连接管理的 header: `Connection`

`Connection` 一共有两种值： `keep-alive` 和 `close`

如果 http client 收到的响应中有头： `Connection: close` , 那么 client 就会主动断开这个 tcp 连接。

### HTTP2/gRPC

HTTP2 请求过程

![http2流程](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/12-01-Zvv7Sa.png)

1. client 与 server 建立一个 tcp 连接
2. client 在某个 tcp 连接上新建 stream（HTTP2 在 tcp 层之上封装了一个 stream 的逻辑层）
3. client 的请求会基于某个 stream 来发送
4. 第3步发送的 reqeust 对应的请求也会在对应的 stream 上发送回来
5. 当在一个 stream 上完成了生命周期后就会关闭当前这个 stream
6. 如果要开始一个新的请求则 client 会主动创建新的 stream
7. 如果 server 要想断开 tcp 连接，那么 server 主动创建一个 stream 发送 goaway 帧
8. 当 client 收到 goaway 帧后，就会创建新的连接，把新的请求放到新连接上的 stream 上发送
9. 等老连接上所有 stream 都关闭后 client 就会关闭 tcp 连接

**注意：** 每个 stream 都有唯一的 id 号码（31位字节的无符号整数标识），基于同一个 tcp 连接的 id 号码是递增的，client 主动创建的 stream 的 id 为奇数，server 主动创建的 stream id 为偶数

由于 HTTP2 在传输层上又封装了一个逻辑 stream 层，所以在处理断连接的时候过程尤为复杂

### Goaway 中的细节

goaway 帧中会带上一个 id 号码，这个号码表示当前收到 client 建立的 stream 中最大的 id 号码（id 号码是自增的），这个 id 号的意义表示 server 不再处理比这个 id 号大的 stream。

client 收到后会读取 goaway 帧中的 id 号码，会比较在本地正在处理的 stream 如果存在比 goaway 中 id 号大的 stream 会在新的 tcp 连接上重试。

![stream状态图](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/12-02-tyZAfW.png)

如上图所示：

client 侧已经发出了三个 stream, 但是 server 侧只收到了 stream 为 1，3 的数据包，这个时候 stream id 为 5 的数据包还在网络上，那么这个时候 server 给 client 发送 Goaway 帧中 id 为 3。

当 client 收到这个 Goaway 帧后，取出 id 为 3，就会和本地已经发出去的 stream 做比较，比这个大的 stream 就会新建一个 tcp 连接，然后在新连接上重试。

如上文所述，就可以实现 HTTP2 server 的优雅暂停和重启。

### gRPC 两次 Goaway

如果仔细思考前文：【Goaway 中的细节】就会发现，client 侧记录的 stream id 号和 server 侧记录的 id 号没对齐，这是由于网络传输需要时间造成了。那么设计一个怎样的机制能保证 server 侧在发送 Goaway 帧的时候，填入的 stream id 也是 client 侧最大的 id 呢？

[为什么gRPC要改为两次Goaway](https://github.com/grpc/grpc-go/issues/1387)

我们先看改之后的逻辑是怎样的，再来回顾改成两次 Goaway 后有什么好处。

#### server 侧的逻辑

![server](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/12-02-p7AHmw.png)

1. server 收到要优雅退出的指令后先发送 Goaway 帧(stream id 为 MaxUint31)，然后发送 Ping 帧
2. client 收到 Ping 帧，马上回复 Ping ACK 帧
3. server 收到 Ping ACK 帧后再发送一个 Goaway 帧(stream id 为当前收到的 stream 中最大的值)

[**server 收到要优雅退出的指令**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L1287)

[**server 第一次发送 Goaway 帧**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L1338)

[**server 发送 Ping 帧**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L1341)

[**server 收到 Ping ACK 帧，并通知发送第二次 Goaway 帧**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L836)

[**server 收到通知，然后发送第二次 Goaway**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L1338-L1343)

[**server 真正发送第二次 Goaway 的地方**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_server.go#L1310)

#### client 侧的逻辑

![client](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/12-02-rSlP2y.png)

1. 当 server 侧第一次发送 Goaway 帧过后，client 会收到第一次 Goaway 帧，然后记录一下已经收到过 Goaway 帧
2. client 会把范围为：currentID < streamID && streamID <= upperLimit 的数据进行重试(upperLimit 取 prevGoAwayID 的值，如果 prevGoAwayID 为 0，upperLimit 取 MaxUint32)，然后赋值：prevGoAwayID = currentID
3. 当第二次收到 Goaway 帧后会重复第2步

[**client 侧对应的源码**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1178)

[**client 第一次收到 Goaway**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1213-L1220)

[**标记已经收到过 Goaway 帧**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1214)

[**第一次收到的 ID 为 MaxUint31，client 跳过重试**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1224-L1234)

[**记录本地收到 Goaway 的 id 号码**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1235)

[**第二次收到 Goaway**](https://github.com/grpc/grpc-go/blob/v1.42.x/internal/transport/http2_client.go#L1207)

prevGoAwayID：为上一次收到 Goaway 帧记录下来的 id 号码，如果未收到过 Goaway 帧，此值为 0

上图的流程中，server 一共发送了两次 Goaway 帧，这两次 Goaway 帧会间隔一个 RTT(Round-Trip Time, 往返时间) 时间, 这个时间是通过发送一个 Ping 帧来实时计算，这个等待的间隔时间内就能保证网络上传输的数据包没有滞留在网络中(为什么一定能保证呢？因为 tcp 是具有发送窗口的)，当 server 收到了 Ping ACK 的时候，取到的 stream id 的最大值一定是 client 侧的最大值。

为什么一定要保证 server 侧发送 Goaway 的时候填入的 id 要和 client 一致呢？我自己的理解是如果不一致 client 就必须保存活跃的数据(已经发送但是还没收到响应的数据)，因为有可能需要重试这些数据。新建一个 tcp 进行重试除了花费了更多的时间，也需要消耗更多的资源。

为什么第一次发送的 Goaway 帧中的 id 号码为 MaxUint31 呢？我个人理解还是为了兼容老版本，因为在老版本的 gRPC-go 中是只有发送一次 Goaway 帧的逻辑

gRPC中还有很多条件要处理，上文只展示了重点处理的逻辑

## 某些微服务场景

在大规模的微服务场景下，如果没有优雅断连的机制会是怎样一种局面。

如果没有优雅断连，但是需要请求数据的无损需要怎么做呢？

第一种办法：

1. 在停止进程前需要反注册服务，然后进程一直等，等到注册中心没有流量调此进程或者连接所有都断开，然后停止进程

此过程需要依靠注册中心通知所有的调用方，依赖注册中心去通知是不可靠的，因为有的调用方可能和注册中心失联了或者节点太多通知很慢。
如果要保证 100% 没有请求再继续调用了，那么肯定是要所有连接都断开

第二种办法：

1. 在微服务平台去把这台机器的流量摘掉，或者把这个实例置为下线(本质就是让注册中心去通知所有调用放不要再调用此实例了)
2. 然后人工的去看这个实例的监控是否有流量了(或者看是否还有和这个进程或者端口有连接，不能看是否有请求数)，然后再去重启或者更新进程，或者说重启更新容器

此办法也能做到 100% 的流量无损，弊端也很突出。研发心智成本高，如果实例一旦多起来那心智成本更高，也严重影响了上线速度。

## 模仿 Goaway

在上文说到微服务场景中怎么用类似 Goaway 的机制来解决呢？

gRPC 中那么复杂是因为 HTTP2 协议中 stream 的生命周期复杂的复杂。有多复杂请看下图

```txt
   The lifecycle of a stream is shown in Figure 2.

                                +--------+
                        send PP |        | recv PP
                       ,--------|  idle  |--------.
                      /         |        |         \
                     v          +--------+          v
              +----------+          |           +----------+
              |          |          | send H /  |          |
       ,------| reserved |          | recv H    | reserved |------.
       |      | (local)  |          |           | (remote) |      |
       |      +----------+          v           +----------+      |
       |          |             +--------+             |          |
       |          |     recv ES |        | send ES     |          |
       |   send H |     ,-------|  open  |-------.     | recv H   |
       |          |    /        |        |        \    |          |
       |          v   v         +--------+         v   v          |
       |      +----------+          |           +----------+      |
       |      |   half   |          |           |   half   |      |
       |      |  closed  |          | send R /  |  closed  |      |
       |      | (remote) |          | recv R    | (local)  |      |
       |      +----------+          |           +----------+      |
       |           |                |                 |           |
       |           | send ES /      |       recv ES / |           |
       |           | send R /       v        send R / |           |
       |           | recv R     +--------+   recv R   |           |
       | send R /  `----------->|        |<-----------'  send R / |
       | recv R                 | closed |               recv R   |
       `----------------------->|        |<----------------------'
                                +--------+

          send:   endpoint sends this frame
          recv:   endpoint receives this frame

          H:  HEADERS frame (with implied CONTINUATIONs)
          PP: PUSH_PROMISE frame (with implied CONTINUATIONs)
          ES: END_STREAM flag
          R:  RST_STREAM frame

                          Figure 2: Stream States
```

很多 RPC 协议都没这么发复杂，这里我们以 dubbo 协议为例。

1. server 收到停止信号后，停止接受新连接，然后向 client 发送 Goaway
2. client 收到 Goaway 后重连接池中移除该连接，然后等待所有请求处理完成，然后关闭连接
3. server 一直等待，等到所有连接都关闭然后停止进程

以上流程相比 gRPC 简化了很多。
