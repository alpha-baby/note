# mosn简介

MOSN 是一款使用 Go 语言开发的网络代理软件，作为云原生的网络数据平面，旨在为服务提供多协议，模块化，智能化，安全的代理能力。MOSN 是 Modular Open Smart Network 的简称。MOSN 可以与任何支持 xDS API 的 Service Mesh 集成，亦可以作为独立的四、七层负载均衡，API Gateway，云原生 Ingress 等使用。

> 自己对mosn的所有了解还不是很多，目前只了解了部分主体代码，所以简介直接复制于官网
> [mosn官网](https://mosn.io/)

# mosn源码分析建议

对于新手拿到一个陌生的golang项目，如果易上手就直接去看代码压力是比较大的，特别是对代码结构不熟悉的情况下(golang的设计单元类似java，用不同的包封装代码，golang中一个目录就代指一个包，我指的代码结构指：项目中都有什么包，这些包是干嘛的，这些包的调用顺序是怎样的，项目提供的某个功能的源码被封装到了哪个包中)

**个人认为**：对一个源代码的阅读需要带着自己明确的目前出发，比如我的目标就是对mosn所有的功能都了解。我对自己的目的梳理了如下的小目标：

1. 项目中都有什么包
2. 这些包是干嘛的
3. 这些包的调用顺序是怎样的
4. 项目提供的某个功能的源码被封装到了哪个包中

# mosn源码分析思路

golang的一大特殊就是书写简单，语法简洁吗，相比java、python等相对简单。

mosn项目中，提供了`Makefile`，从编译文件中，我们可以查看mosn项目是怎样被编译的。

```makefile
build-local:
	@rm -rf build/bundles/${MAJOR_VERSION}/binary #  清空二进制文件存放的目录
	CGO_ENABLED=0 go build\ # CGO_ENABLED=0 禁用了CGO，如果要详细了解CGO，可以看go官网，或者《go高级编程》
		-ldflags "-B 0x$(shell head -c20 /dev/urandom|od -An -tx1|tr -d ' \n') -X main.Version=${MAJOR_VERSION}(${GIT_VERSION}) -X ${PROJECT_NAME}/pkg/types.IstioVersion=${ISTIO_VERSION}" \
		-v -o ${TARGET} \
		${PROJECT_NAME}/cmd/mosn/main 
	mkdir -p build/bundles/${MAJOR_VERSION}/binary # 一下都是些附加操作
	mv ${TARGET} build/bundles/${MAJOR_VERSION}/binary
	@cd build/bundles/${MAJOR_VERSION}/binary && $(shell which md5sum) -b ${TARGET} | cut -d' ' -f1  > ${TARGET}.md5
	cp configs/${CONFIG_FILE} build/bundles/${MAJOR_VERSION}/binary
	cp build/bundles/${MAJOR_VERSION}/binary/${TARGET}  build/bundles/${MAJOR_VERSION}/binary/${TARGET_SIDECAR}
```

* `-ldflags`: 在编译源代码的时候，把参数传递go工具链中去调用，例如：`-s`: 去掉符号表，`-w`: 去掉调试信息，不能gdb调试了,`-X: 表示给某个包中的全局变量赋值`。

> 关于go build 更多的参数可参考：
> https://blog.csdn.net/zl1zl2zl3/article/details/83374131

在`Makefile`中我认为对新手最重要的是：${PROJECT_NAME}/cmd/mosn/main(mosn.io/mosn/cmd/mosn/main)

在启动可以知道，mosn整个项目的主函数在哪儿，然后就可以找到整个项目的起点。

## mosn 的 main 包

从以上的分析中，可以找到在主函数在：`mosn.io/mosn/cmd/mosn/main/mosn.go`:

在主函数上放可以看到一个全局变量：`Version`，这个变量就是我们在编译mosn项目的时候：`go build -ldflags "-X main.Version=xxx" ` 来传递的。

main包中的函数：`newMosnApp`

```golang
func newMosnApp(startCmd *cli.Command) *cli.App {
	app := cli.NewApp()
	app.Name = "mosn"
	app.Version = Version
	app.Compiled = time.Now()
	app.Copyright = "(c) " + strconv.Itoa(time.Now().Year()) + " Ant Financial"
	app.Usage = "MOSN is modular observable smart netstub."
	app.Flags = cmdStart.Flags

	//commands
	app.Commands = []cli.Command{
		cmdStart,
		cmdStop,
		cmdReload,
	}

	//action
	app.Action = func(c *cli.Context) error {
		// ....
	}
	return app
}
```

可以看到mosn用了这个库：`"github.com/urfave/cli"`, 这个第三方包是用来构建命令行工具的，需要自行去github上学习下这个库是怎么使用的。

根据`Makefile`, 可以编译出本地可执行的二进制文件，目前mosn最新版本是：**v0.15.0**，我这里使用如下命令来编译：

```bash
make build-local
```

编译好的可执行程序就在目录：`build/bundles/v0.15.0/binary`中，我们可以使用`--help`参数看下文档：

```bash
./mosn -h
NAME:
   mosn - MOSN is modular observable smart netstub.

USAGE:
   mosn [global options] command [command options] [arguments...]

VERSION:
   v0.15.0(07a90eb3)

COMMANDS:
     start    start mosn proxy
     stop     stop mosn proxy
     reload   reconfiguration
     help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   # ......
   --help, -h                               show help
   --version, -v                            print the version

COPYRIGHT:
   (c) 2020 Ant Financial
```

可以看到，mosn提供了三个命令分别是：

```bash
start    start mosn proxy
stop     stop mosn proxy
reload   reconfiguration
```

## http sever demo

在mosn官网上给我提供了一些简单的上手示例，我们可以使用这些示例来简单的了解mosn，我这里使用[http](https://github.com/mosn/mosn/blob/master/examples/cn_readme/http-sample/README.md)这个示例。

**启动http server**

```bash
go run ./server.go # 监听本地8080端口的http 服务
```

然后先启一个mosn服务端：

```bash
./mosn start -c server_config.json
# ....
2020-09-02 14:22:02,901 [INFO] [admin store] [start service] start service Mosn Admin Server on [::]:34902
2020-09-02 14:23:12,849 [INFO] remote addr: 127.0.0.1:8080, network: tcp
# .....
```

启动后我们可以看到，server端监听了本地34902端口，并且设置了路由`127.0.0.1:8080`,这个设置的路由就是上面我们启动的http服务。

在mac上我们可以使用如下命令可查看启动的mosn程序监听的其他端口：

```bash
lsof -nP | grep TCP | grep LISTEN
# ...
29:12995:server    52705 fujianhao3    3u     IPv4 0x1e2ca72e2bd85243         0t0                 TCP 127.0.0.1:8080 (LISTEN)
30:13277:mosn      55236 fujianhao3    7u     IPv6 0x1e2ca72e281b1e13         0t0                 TCP *:34902 (LISTEN)
31:13279:mosn      55236 fujianhao3    9u     IPv4 0x1e2ca72e05137603         0t0                 TCP 127.0.0.1:2046 (LISTEN)
```

可以看到mosn除了监听端口：34902， 还监听了：2046端口。

然后我们用如下命令来访问下2046端口：

```bash
curl http://127.0.0.1:2046/
Method: GET
Protocol: HTTP/1.1
Host: 127.0.0.1:2046
RemoteAddr: 127.0.0.1:58875
RequestURI: "/"
URL: &url.URL{Scheme:"", Opaque:"", User:(*url.Userinfo)(nil), Host:"", Path:"/", RawPath:"", ForceQuery:false, RawQuery:"", Fragment:""}
Body.ContentLength: 0 (-1 means unknown)
Close: false (relevant for HTTP/1 only)
TLS: (*tls.ConnectionState)(nil)

Headers:
Accept: */*
Content-Length: 0
User-Agent: curl/7.64.1
```

访问完成后还可以看到mosn输出了如下的日志：

```txt
2020-09-02 14:23:12,849 [INFO] remote addr: 127.0.0.1:8080, network: tcp
2020-09-02 14:23:12,850 [INFO] [network] [read loop] do read err: EOF
```

http sever 输出了如下日志：

```txt
[UPSTREAM]receive request /
```

## 配置文件浅析

分析下配置文件，以`server_config.json`配置文件为例：

```json
{
	"close_graceful" : true,
	"servers":[
		{
			"default_log_path":"stdout",
			"routers":[ 
				{ // tip1
					"router_config_name":"server_router",
					"virtual_hosts":[{
						"name":"serverHost",
						"domains": ["*"],
						"routers": [
							{
								"match":{"prefix":"/"},
								"route":{"cluster_name":"serverCluster"}
							}
						]
					}]
				}
			],
			"listeners":[
				{ // tip2
					"name":"serverListener",
					"address": "127.0.0.1:2046",
					"bind_port": true,
					"filter_chains": [{
						"filters": [
							{
								"type": "proxy",
								"config": {
									"downstream_protocol": "Http1",
									"upstream_protocol": "Http1",
									"router_config_name":"server_router"
								}
							}
						]
					}]
				}
			]
		}
	],
	"cluster_manager":{
		"clusters":[
			{ // tip3
				"name":"serverCluster",
				"type": "SIMPLE",
				"lb_type": "LB_RANDOM",
				"max_request_per_conn": 1024,
				"conn_buffer_limit_bytes":32768,
				"hosts":[
					{"address":"127.0.0.1:8080"}
				]
			}
		]
	},
	"admin": {
		"address": {
			"socket_address": {
				"address": "0.0.0.0",
				"port_value": 34902
			}
		}
	}
}
```

其中**34902**端口启动的`admin`服务。

我在以上配置文件中标志了三个地方，首先在**tip2**处：监听了本地2046端口，然后配置上下游协议为http1.x 的协议，router_config_name设置为了`"server_router"`, 其中`"server_router"`指向了：**tip1**，而**tip1**中的配置：`"route":{"cluster_name":"serverCluster"}`，又指向了**tip3**，**tip3**中的配置又指向了我们本地启动的http server(127.0.0.1:8080)。

这样一梳理，我们就可以对mosn有了一个基本的了解，接下来我们在启动一个client端：

```bash
./mosn start -c client_config.json 
# ....
2020-09-02 14:52:27,138 [INFO] [server] [conn handler] [add listener] add listener: 127.0.0.1:2045
# ....
2020-09-02 14:52:27,138 [INFO] [admin store] [start service] start service Mosn Admin Server on [::]:34901
```

查看下监听的所有端口：

```bash
lsof -nP | grep TCP | grep LISTEN
# ....
33:13459:mosn      62685 fujianhao3    7u     IPv6 0x1e2ca72e281ae0d3         0t0                 TCP *:34901 (LISTEN)
34:13461:mosn      62685 fujianhao3    9u     IPv4 0x1e2ca72e266b6863         0t0                 TCP 127.0.0.1:2045 (LISTEN)
```

使用一下命令再访问下client：

```bash
curl http://127.0.0.1:2045/
# ...
# 同样可以看到类似的返回结果
```

根据以上分析的思路可以自己去分析下，在配置文件`client_config.json`中流量的走向。同时也可以熟悉下mosn的配置文件格式。

以上的两个配置文件：`server_config.json`,`client_config.json`也可以合并写成一个，我们可以参考代码中的配置文件：`configs/mosn_config.json`，根据以上http demo的分析我们就可以很简单的看懂配置文件了。

## mosn start 命令

我们使用`start`子命令来启动mosn，说明mosn的主要实现都在这里面。

在`cmdStart -> Action -> mosn.Start(conf)`: 我们可以找到mosn的启动在这个包下：`pkg/mosn`

```golang
// Start mosn's server
func Start(c *v2.MOSNConfig) {
	//log.StartLogger.Infof("[mosn] [start] start by config : %+v", c)
	Mosn := NewMosn(c)
	Mosn.Start()
	Mosn.wg.Wait()
}
```

同时还可以发现该目录下还有个测试文件：`starter_test.go`。

**提示**：查看单元测试文件也可以很有效的了解一个项目的源代码。

我们可以先看下这个测试文件，可以看到分别一个两个配置：`mosnConfigOld`, `mosnConfigNew`，可以自行对比下两个不同的配置。

测试函数：`TestNewMosn`中,通过注释我们就可以了解到，这是为了测试新格式的配置和老格式的配置的兼容性测试，读者还可以自行debug去运行这个测试函数然后去看里面的执行流程。

通过这个测试函数，我们可以看到，一个重要的函数就是：`NewMson(cfg)`，通过配置实例化一个mosn对象。

```golang
// Mosn class which wrapper server, mosn类是对server的一个包装，这个server就是指的："mosn.io/mosn/pkg/server" -> server.Server,后面我们会分析到这里去
type Mosn struct {
	servers        []server.Server
	clustermanager types.ClusterManager
	routerManager  types.RouterManager
	config         *v2.MOSNConfig
	adminServer    admin.Server
	xdsClient      *xds.Client
	wg             sync.WaitGroup
    // for smooth upgrade. reconfigure
    // 热更新和重加载配置文件用来传输数据的socket，官网对热更新有讲解文章
	inheritListeners  []net.Listener
	inheritPacketConn []net.PacketConn
	listenSockConn    net.Conn
}
```

虽然`Mosn.servers`是一个切片，但是目前mosn只支持配置一个server，我们可以看源码：

```golang
func NewMosn(c *v2.MOSNConfig) *Mosn {
    // ...
    if srvNum == 0 {
        og.StartLogger.Fatalf("[mosn] [NewMosn] no server found")
    } else if srvNum > 1 {
        log.StartLogger.Fatalf("[mosn] [NewMosn] multiple server not supported yet, got %d", srvNum)
    }
    // ...
}
```

# mosn中的socket源码流程

在上问中使用http demo 分析了mosn的配置文件，通过配置文件我们知道，我们是访问mosn的**2045**或者**2046**端口就可以代理到`127.0.0.1:8080`http 服务。所以mosn一定监听了一个**2045**端口，在golang的网络编程中我们一般，都会使用:`net.Listen()`来监听一个tcp socket。

直接使用IDE或者其他方式在项目中全局搜索：`"net.Listen"`, 可以搜出来很多(忽略掉测试文件)，但是一个个都点进去看发现都不对，后来没有太好的思路，只能一个一个的看`pkg`包下的不同目录，找了一段时间，终于不负辛苦让我找到了：`pkg/network/listener.go -> func (l *listener) listen(lctx context.Context) {}`, 在这个函数中就包装了这个go内置包中的监听函数：`net.ListenTCP`。

如果对golang的socket编程不了解可以先去看看net包下的源码或者看些别人的解析，这里我提供一个主体结构体和接口的结构图，帮助你去阅读net包的源码：

![golang net包](https://tva1.sinaimg.cn/large/007S8ZIlly1gicdgmeaalj31h60n2gok.jpg)

`net.ListenTCP()`函数就是返回的一个`net.TCPListener`结构体。

再次使用全局搜索，可以发现，并没有其他地方还有这个函数了，所以我们可以初步推断，我们在上文中运行的demo中的配置的: `127.0.0.1:2045`就应该是再这里。

其实我们不用猜，我们直接添加日志来检验下就行，为了方便我这是使用的goland，我直接配置一个 “Run/Debug -》Configurations” 直接点左上角的加号添加一个**go build**, 如果你也用goland，你可以按照我这样配置

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gicdx58z3xj30tr0jg40v.jpg)

然后在函数中加上日志：

```golang
func (l *listener) listen(lctx context.Context) error {
	var err error
	var rawl *net.TCPListener
	var rconn net.PacketConn
    log.DefaultLogger.Infof("net.TCPListen: %v %v",l.network, l.localAddress.String()) # 添加的输出日志
    // ....
}
```

然后直接点击启动就可以在日志中看到输出去的日志：

```golang
[INFO] net.TCPListen: tcp 127.0.0.1:2046
```

那么我们就可以确认，就是这里监听了本地代理流量的端口了。

## 查找主函数到本地的调用过程

### pkg/network/listener.go

我们可以直接查找是谁调用了: `func (l *listener) listen(lctx context.Context)`, 查找结果如下：

```golang
func (l *listener) Start(lctx context.Context, restart bool) {
    // ...
    l.listen(lctx)
    // ...
}
```

我们可以看到在以上函数的调用者是一个结构体：

```golang
type listener struct {
    // ...
    rawl                    *net.TCPListener // 重要
    packetConn              net.PacketConn
    config                  *v2.Listener
    // ...
    cb                      types.ListenerEventListener // 新tcp连接回调事件函数
}
```

对以上结构体的成员分析，可以知道在`pkg/network/listen.go -> listener`是对底层 net.TCPListener 的一个包装。

如果对网络编程比较了解的都知道，`net.TCPListener`，肯定会有`accept`函数去等待连接，这个等待连接的函数就在：`pkg/network/listener.go`

```golang
func (l *listener) acceptEventLoop(lctx context.Context) {
    for { // 循环监听tcp连接
        l.accept(lctx)
    }
}
```

```golang
func (l *listener) accept(lctx context.Context) error {
    rawc, err := l.rawl.Accept()
    if err != nil {
        return err
    }
    // TODO: use thread pool
    utils.GoWithRecover(func() {
        l.cb.OnAccept(rawc, l.useOriginalDst, nil, nil, nil)
    }, nil)
    return nil
}
```

可以看到如果有新的tcp连接到来，会回调：`l.cb.OnAccept()`，其中cb是类型：`types.ListenerEventListener`，这是一个接口类型，为什么会有这个接口类型，其本质就是为了mock。分析这个接口，可以知道实现了这个接口类型的结构体是：`pkg/server/handler.go` -> `type activeListener struct`.

### pkg/server/handler.go

在对函数：`func (l *listener) Start(...)` 进行查找会发现有两处都调用了，分别是：

1. 位于：`pkg/server/handler.go`: `func (al *activeListener) GoStart(lctx context.Context)`
2. 位于：`pkg/server/adapter.go`: `func (adapter *ListenerAdapter) AddOrUpdateListener(serverName string, lc *v2.Listener) `

因为作为Service Mesh中的数据面，mosn可以动态接收到控制面板通过xDS标准下发的动态配置，如果收到新的配置需要监听本地端口，其中第2处是用来调用新增本地端口的监听。

第一处就是主流程中的本地端口的监听，代码如下：

```golang
func (al *activeListener) GoStart(lctx context.Context) {
    utils.GoWithRecover(func() {
        al.listener.Start(lctx, false)
    }, func(r interface{}) {
        // TODO: add a times limit?
        al.GoStart(lctx)
    })
}
```

我们可以很容易的看出来，这里做了一个recover的重启，如果启动监听报错，那么这里就会递归的调用：`GoStart`, 在v0.15.0 中还存在一个bug，目前我已经把这个bug给修复了，bug的详细情况情况可以查看：https://github.com/mosn/mosn/issues/1334

这个bug其实在golang的面试中也挺常见的。

这里的指针调用者是：`activeListener`，具体的调用是：

```golang
// ListenerEventListener
type activeListener struct {
    listener                    types.Listener // 重点
    listenerFiltersFactories    []api.ListenerFilterChainFactory
    networkFiltersFactories     []api.NetworkFilterChainFactory
    streamFiltersFactoriesStore atomic.Value // store []api.StreamFilterChainFactory
    listenIP                    string
    listenPort                  int
    conns                       *list.List
    connsMux                    sync.RWMutex
    handler                     *connHandler
    stopChan                    chan struct{}
    stats                       *listenerStats
    accessLogs                  []api.AccessLog
    updatedLabel                bool
    idleTimeout                 *api.DurationConfig
    tlsMng                      types.TLSContextManager
}
```

在上文中，我们分析到，当监听到新的tcp连接到来后会有一个事件回调函数，这个回调本质上势函数：

```golang
// pkg/server/handler.go
// ListenerEventListener
func (al *activeListener) OnAccept(rawc net.Conn, useOriginalDst bool, oriRemoteAddr net.Addr, ch chan api.Connection, buf []byte) {
    // ...
    // 对net.Conn 进行了二次包装
    arc := newActiveRawConn(rawc, al)
    // ...
    arc.ContinueFilterChain(ctx, true)
```

```golang
func (arc *activeRawConn) ContinueFilterChain(ctx context.Context, success bool) {
    // ...
    arc.activeListener.newConnection(ctx, arc.rawc)
}
```

`activeRawConn`的具体结构如下：

```golang
type activeRawConn struct {
	rawc                net.Conn // 是对golang 底层 net.Conn的封装，可以看上文中我提供的net包的结构图
	rawf                *os.File
	ctx                 context.Context
	originalDstIP       string
	originalDstPort     int
	oriRemoteAddr       net.Addr
	useOriginalDst      bool
	rawcElement         *list.Element
	activeListener      *activeListener
	acceptedFilters     []api.ListenerFilterChainFactory
	acceptedFilterIndex int
}
```

```golang
// 
func (al *activeListener) newConnection(ctx context.Context, rawc net.Conn) {
    conn := network.NewServerConnection(ctx, rawc, al.stopChan) // 再次包装 net.Conn
    al.OnNewConnection(newCtx, conn)
}
```

具体的包装结构体在：`pkg/network/connection.go` -> 

```golang
type connection struct {
	rawConnection        net.Conn // 再次对net.Conn的封装，这里mosn所有收到的需要代理的流量数据都是从这里读取出来的
```

读取数据的函数是：`func (c *connection) Start(lctx context.Context)`虽然，net.Conn的接口很简单就三个主要的方法，但是mosn中用：`connection`来封装了net.Conn，随意就会变得很复杂，会处理很多逻辑，里面还有很多buffer的处理。如果对mosn熟悉后，可对里面的代码进行详细的阅读。

```golang
// al.OnNewConnection(newCtx, conn)
func (al *activeListener) OnNewConnection(ctx context.Context, conn api.Connection) {
    ac := newActiveConnection(al, conn) // 对 pkg/network/connection.go -> connection 进行了包装
    al.connsMux.Lock()
    e := al.conns.PushBack(ac)
    al.connsMux.Unlock()
    // start conn loops first 
    // 这里就是上文所分析的循环读取数据的地方，
    conn.Start(ctx)
}
```

### pkg/network/connection.go

对`connection`包装的结构体是：

```golang
type activeConnection struct {
    element  *list.Element
    listener *activeListener
    conn     api.Connection // 对上文中 connection 结构体的封装
}
```

循环读取数据的结构体的具体逻辑如下：

```golang
func (c *connection) Start(lctx context.Context) {
    // udp downstream connection do not use read/write loop
    if c.network == "udp" && c.rawConnection.RemoteAddr() == nil {
        return
    }
    c.startOnce.Do(func() {
        if UseNetpollMode { // UseNetpollMode 这个表示mosn不同的网络IO模型了，具体类型可参考官网上的这里：https://mosn.io/docs/concept/core-concept/#io-%E6%A8%A1%E5%9E%8B
            c.attachEventLoop(lctx)
        } else {
            c.startRWLoop(lctx)
        }
    })
}
```

回到最初的：`pkg/server/handler.go` -> `activeListener` 结构体。

我们再查找哪个地方实例化了`activeListener`结构体，在如下函数中实例化了这个接头体：

```golang
// pkg/server/handler.go
func (ch *connHandler) AddOrUpdateListener(lc *v2.Listener) (types.ListenerEventListener, error) {
    // ...
    al, err = newActiveListener(l, lc, als, listenerFiltersFactories, networkFiltersFactories, streamFiltersFactories, ch, listenerStopChan)
    // ...
}
```

指针调用者的具体类容是：

```golang
type connHandler struct {
    numConnections int64
    listeners      []*activeListener // 封装多个 activeListener
    clusterManager types.ClusterManager
}
```

### pkg/server/server.go

再继续查看是哪里调用了`Newhandler`来实例化结构体：`type connHandler struct`,经过查找可以发现，在如下函数中进行了实例化：

```golang
// pkg/server/server.go
// NewServer get a new server
func NewServer(config *Config, cmFilter types.ClusterManagerFilter, clMng types.ClusterManager) Server {
    server := &server{ // 对 connHandler 进行封装
        serverName: config.ServerName,
        stopChan:   make(chan struct{}),
        handler:    NewHandler(cmFilter, clMng),
    }
    // 用适配器再次封装了 connHandler
    initListenerAdapterInstance(server.serverName, server.handler)

    servers = append(servers, server)

    return server
}
```

`server` 结构体具体的结构如下：

```golang
type server struct {
    serverName string // 目前mosn只支持配置一个server 所以这个serverName则为空字符串
    stopChan   chan struct{}
    handler    types.ConnectionHandler // 对 connHandler 的封装
}
```

哪儿调用了`NewServer`呢？我们继续查找，可以找到，就只有在`pkg/mosn/starter.go` -> `func NewMosn(c *v2.MOSNConfig)` 中调用了`NewMosn`。

上文都是通过文字的形式反向推理，梳理了从主函数到底层网络的监听的主干流程。分析到这里，我们便可以知道了mosn，通过很多不同结构体对go内置包中的`net.Conn`, `net.TCPListener`的封装来实现网络数据的接收和发送，并在其中实现了数据的过滤，路由，协议的解析等细节的功能。

## 结构体封装流程(图)

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gid8ut09hvj310v0u0q70.jpg)

如果在读完文字叙述后，还不是很理解，可以对照图片，再去看一遍前文，