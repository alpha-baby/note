# 百万 Go TCP 连接的思考: epoll方式减少资源占用

==============================
原文链接：https://colobu.com/2019/02/23/1m-go-tcp-connection/

前几天 Eran Yanay 在 Gophercon Israel 分享了一个讲座：[Going Infinite, handling 1M websockets connections in Go](https://speakerdeck.com/eranyanay/going-infinite-handling-1m-websockets-connections-in-go), 介绍了使用Go实现支持百万连接的websocket服务器，引起了很大的反响。事实上，相关的技术在2017年的一篇技术中已经介绍： [A Million WebSockets and Go](https://medium.freecodecamp.org/million-websockets-and-go-cc58418460bb), 这篇2017年文章的作者Sergey Kamardin也就是 Eran Yanay 项目中使用的ws库的作者。

第一篇 [百万 Go TCP 连接的思考: epoll方式减少资源占用](https://colobu.com/2019/02/23/1m-go-tcp-connection/)  
第二篇 [百万 Go TCP 连接的思考2: 百万连接的吞吐率和延迟](https://colobu.com/2019/02/27/1m-go-tcp-connection-2/)  
第三篇 [百万 Go TCP 连接的思考: 正常连接下的吞吐率和延迟](https://colobu.com/2019/02/28/1m-go-tcp-connection-3/)

相关代码已发布到github上: [1m-go-tcp-server](https://github.com/smallnest/1m-go-tcp-server)。

Sergey Kamardin 在 [A Million WebSockets and Go](https://medium.freecodecamp.org/million-websockets-and-go-cc58418460bb) 一文中介绍了epoll的使用([mailru/easygo](https://github.com/mailru/easygo),支持epoll on linux, kqueue onbsd, darwin), ws的zero copy的upgrade等技术。

Eran Yanay的分享中对epoll的处理做了简化，而且提供了docker测试的脚本，很方便的在单机上进行百万连接的测试。

2015年的时候我也曾作为百万连接的websocket的服务器的比较：[使用四种框架分别实现百万websocket常连接的服务器](https://colobu.com/2015/05/22/implement-C1000K-servers-by-spray-netty-undertow-and-node-js/) 、[七种WebSocket框架的性能比较](https://colobu.com/2015/07/14/performance-comparison-of-7-websocket-frameworks/)。应该说，只要服务器硬件资源足够(内存和CPU), 实现百万连接的服务器并不是很难的事情，

操作系统会为每一个连接分配一定的内存空间外（主要是内部网络数据结构sk_buff的大小、连接的读写缓存，[sof](https://stackoverflow.com/questions/8646190/how-much-memory-is-consumed-by-the-linux-kernel-per-tcp-ip-network-connection)）,虽然这些可以进行调优，但是如果想使用正常的操作系统的TCP/IP栈的话，这些是硬性的需求。刨去这些，不同的编程语言不同的框架的设计，甚至是不同的需求场景，都会极大的影响TCP服务器内存的占用和处理。

一般Go语言的TCP(和HTTP)的处理都是每一个连接启动一个goroutine去处理，因为我们被教导goroutine的不像thread, 它是很便宜的，可以在服务器上启动成千上万的goroutine。但是对于一百万的连接，这种**goroutine-per-connection**的模式就至少要启动一百万个goroutine，这对资源的消耗也是极大的。针对不同的操作系统和不同的Go版本，一个goroutine锁使用的最小的栈大小是2KB ~ 8 KB ([go stack](https://github.com/golang/go/blob/release-branch.go1.11/src/runtime/stack.go#L64-L82)),如果在每个goroutine中在分配byte buffer用以从连接中读写数据，几十G的内存轻轻松松就分配出去了。

所以Eran Yanay使用epoll的方式代替**goroutine-per-connection**的模式，使用一个goroutine代码一百万的goroutine, 另外使用ws减少buffer的分配，极大的减少了内存的占用，这也是大家热议的一个话题。

当然诚如作者所言，他并不是要提供一个更好的优化的websocket框架，而是演示了采用一些技术进行的优化，通过阅读他的slide和代码，我们至少有以下疑问？

*   虽然支持百万连接，但是并发的吞吐率和延迟是怎样的？
*   服务器实现的是单goroutine的处理，如果业务代码耗时较长会怎么样
*   主要适合什么场景？

吞吐率和延迟需要数据来支撑，但是显然这个单goroutine处理的模式不适合耗时较长的业务处理，"hello world"或者直接的简单的memory操作应该没有问题。对于百万连接但是并发量很小的场景，比如消息推送、页游等场景，这种实现应该是没有问题的。但是对于并发量很大，延迟要求比较低的场景，这种实现可能会存在问题。

这篇文章和后续的两篇文章，将测试巨量连接/高并发/低延迟场景的几种服务器模式的性能，通过比较相应的连接、吞吐率、延迟，给读者一个有价值的选型参考。

作为一个更通用的测试，我们实现的是TCP服务器，而不是websocket服务器。

在实现一个TCP服务器的时候，首先你要问自己，到底你需要的是哪一个类型的服务器？

[![](huge-connections.jpg)](https://colobu.com/2019/02/23/1m-go-tcp-connection/huge-connections.jpg)[![](high-throughputs.jpg)](https://colobu.com/2019/02/23/1m-go-tcp-connection/high-throughputs.jpg)[![](low-latency.jpg)](https://colobu.com/2019/02/23/1m-go-tcp-connection/low-latency.jpg)

当然你可能会回答，我都想要啊。但是对于一个单机服务器，资源是有限的，鱼与熊掌不可兼得，我们只能尽力挖掘单个服务器的能力，有些情况下必须通过堆服务器的方式解决，尤其在双十一、春节等时候，很大程度上都是通过扩容来解决的，这是因为单个服务器确确实实能力有限。

尽管单个服务器能力有限，不同的设计取得的性能也是不一样的，这个系列的文章测试不同的场景、不同的设计对性能的影响以及总结，主要包括：

*   百万连接情况下的goroutine-per-connection模式服务器的资源占用
*   百万连接情况下的epoller模式服务器的资源占用
*   百万连接情况下epoller模式服务器的吞吐率和延迟
*   客户端为单goroutine和多goroutine情况下epoller方式测试
*   服务器为多epoller情况下的吞吐率和延迟 (百万连接)
*   prefork模式的epoller服务器 (百万连接)
*   Reactor模式的epoller服务器 (百万连接)
*   正常连接下高吞吐服务器的性能(连接数<=5000)
*   I/O密集型epoll服务器
*   I/O密集型goroutine-per-connection服务器
*   CPU密集型epoll服务器
*   CPU密集型goroutine-per-connection服务器

零、 测试环境的搭建
----------

我们在同一台机器上测试服务器和客户端。首先就是服务器参数的设置，主要是可以打开的文件数量。

`file-max`是设置系统所有进程一共可以打开的文件数量。同时程序也可以通过setrlimit调用设置每个进程的限制。

`echo 2000500 > /proc/sys/fs/file-max`或者 `sysctl -w "fs.file-max=2000500"`可以实时更改这个参数，但是重启之后会恢复为默认值。  
也可以修改`/etc/sysctl.conf`, 加入`fs.file-max = 2000500`重启或者`sysctl -w`生效。

设置资源限制。首先修改`/proc/sys/fs/nr_open`,然后再用`ulimit`进行修改：

```bash
echo 2000500 \> /proc/sys/fs/nr_open

ulimit -n 2000500
```
`ulimit`设置当前shell以及由它启动的进程的资源限制，所以你如果打开多个shell窗口，应该都要进行设置。

当然如果你想重启以后也会使用这些参数，你需要修改`/etc/sysctl.conf`中的`fs.nr_open`参数和`/etc/security/limits.conf`的参数：

```bash
\# vi /etc/security/limits.conf

\* soft nofile 2000500 

\* hard nofile 2000500
```
如果你开启了iptables，iptalbes会使用nf_conntrack模块跟踪连接，而这个连接跟踪的数量是有最大值的，当跟踪的连接超过这个最大值，就会导致连接失败。 通过命令查看

```bash
\# wc -l /proc/net/nf_conntrack

  1024000
```
查看最大值
```bash
\# cat /proc/sys/net/nf\_conntrack\_max

 1024000
```
可以通过修改这个最大值来解决这个问题

在/etc/sysctl.conf添加内核参数 net.nf\_conntrack\_max = 2000500

对于我们的测试来说，为了我们的测试方便，可能需要一些网络协议栈的调优，可以根据个人的情况进行设置。
```bash
sysctl -w fs.file-max=2000500

sysctl -w fs.nr_open=2000500

sysctl -w net.nf\_conntrack\_max=2000500

ulimit -n 2000500

sysctl -w net.ipv4.tcp_mem='131072  262144  524288'

sysctl -w net.ipv4.tcp_rmem='8760  256960  4088000'

sysctl -w net.ipv4.tcp_wmem='8760  256960  4088000'

sysctl -w net.core.rmem_max=16384

sysctl -w net.core.wmem_max=16384

sysctl -w net.core.somaxconn=2048

sysctl -w net.ipv4.tcp\_max\_syn_backlog=2048

sysctl -w /proc/sys/net/core/netdev\_max\_backlog=2048

sysctl -w net.ipv4.tcp\_tw\_recycle=1

sysctl -w net.ipv4.tcp\_tw\_reuse=1
```

另外，我的测试环境是是两颗 E5-2630 V4的CPU, 一共20个核，打开超线程40个逻辑核， 内存32G。

一、 简单的支持百万连接的TCP服务器
-------------------

### 服务器

首先我们实现一个百万连接的服务器，采用每个连接一个goroutine的模式(`goroutine-per-conn`)。

server.go
```go
func main() {

	ln, err := net.Listen("tcp", ":8972")

	if err != nil {

		panic(err)

	}

	go func() {

		if err := http.ListenAndServe(":6060", nil); err != nil {

			log.Fatalf("pprof failed: %v", err)

		}

	}()

	var connections \[\]net.Conn

	defer func() {

		for _, conn := range connections {

			conn.Close()

		}

	}()

	for {

		conn, e := ln.Accept()

		if e != nil {

			if ne, ok := e.(net.Error); ok && ne.Temporary() {

				log.Printf("accept temp err: %v", ne)

				continue

			}

			log.Printf("accept err: %v", e)

			return

		}

		go handleConn(conn)

		connections = append(connections, conn)

		if len(connections)%100 == 0 {

			log.Printf("total number of connections: %v", len(connections))

		}

	}

}

func handleConn(conn net.Conn) {

	io.Copy(ioutil.Discard, conn)

}
```

编译`go build -o server server.go`,然后运行`./server`。

### 客户端

客户端建立好连接后，不断的轮询每个连接，发送一个简单的`hello world\n`的消息。

client.go
```go
var (

	ip          = flag.String("ip", "127.0.0.1", "server IP")

	connections = flag.Int("conn", 1, "number of tcp connections")

)

func main() {

	flag.Parse()

	addr := *ip + ":8972"

	log.Printf("连接到 %s", addr)

	var conns \[\]net.Conn

	for i := 0; i < *connections; i++ {

		c, err := net.DialTimeout("tcp", addr, 10*time.Second)

		if err != nil {

			fmt.Println("failed to connect", i, err)

			i--

			continue

		}

		conns = append(conns, c)

		time.Sleep(time.Millisecond)

	}

	defer func() {

		for _, c := range conns {

			c.Close()

		}

	}()

	log.Printf("完成初始化 %d 连接", len(conns))

	tts := time.Second

	if *connections > 100 {

		tts = time.Millisecond * 5

	}

	for {

		for i := 0; i < len(conns); i++ {

			time.Sleep(tts)

			conn := conns\[i\]

			conn.Write(\[\]byte("hello world\\r\\n"))

		}

	}

}
```

因为从一个IP连接到同一个服务器的某个端口最多也只能建立65535个连接，所以直接运行客户端没办法建立百万的连接。 Eran Yanay采用docker的方法确实让人眼前一亮（我以前都是通过手工设置多个ip的方式实现，采用docker的方式更简单）。

我们使用50个docker容器做客户端，每个建立2万个连接，总共建立一百万的连接。

1

./setup.sh 20000 50 172.17.0.1

`setup.sh`内容如下，使用几M大小的`alpine`docker镜像跑测试：

setup.sh
```bash
#!/bin/bash address, 缺省是 172.17.0.1

CONNECTIONS=$1

REPLICAS=$2

IP=$3

#go build --tags "static netgo" -o client client.go

for (( c=0; c<${REPLICAS}; c++ ))

do

    docker run -v $(pwd)/client:/client --name 1mclient_$c -d alpine /client \

    -conn=${CONNECTIONS} -ip=${IP}

done
```
### 数据分析

使用以下工具查看性能：

*   dstat：查看机器的资源占用（cpu， memory，中断数和上下文切换次数）
*   ss：查看网络连接情况
*   pprof：查看服务器的性能
*   report.sh: 后续通过脚本查看延迟

![没连接前的服务器](https://colobu.com/2019/02/23/1m-go-tcp-connection/1-before-start.png "没连接前的服务器")没连接前的服务器  
![建立百万连接后的服务器](https://colobu.com/2019/02/23/1m-go-tcp-connection/1-connected.png "建立百万连接后的服务器")建立百万连接后的服务器

可以看到建立连接后大约占了19G的内存，CPU占用非常小，网络传输1.4MB左右的样子。

二、 服务器epoll方式实现
---------------

和Eran Yanay最初指出的一样，上述方案使用了上百万的goroutine,耗费了太多了内存资源和调度，改为epoll模式，大大降低了内存的使用。Eran Yanay的epoll实现只针对Linux的epoll而实现，比mailru的easygo实现和使用起来要简单，我们采用他的这种实现方式。

Go的net方式在Linux也是通过epoll方式实现的，为什么我们还要再使用epoll方式进行封装呢？原因在于Go将epoll方式封装再内部，对外并没有直接提供epoll的方式来使用。好处是降低的开发的难度，保持了Go类似"同步"读写的便利型，但是对于需要大量的连接的情况，我们采用这种每个连接一个goroutine的方式占用资源太多了，所以这一节介绍的就是hack连接的文件描述符，采用epoll的方式自己管理读写。

### 服务器

服务器需要改造一下：

server.go

```go
var epoller *epoll

func main() {

	setLimit()

	ln, err := net.Listen("tcp", ":8972")

	if err != nil {

		panic(err)

	}

	go func() {

		if err := http.ListenAndServe(":6060", nil); err != nil {

			log.Fatalf("pprof failed: %v", err)

		}

	}()

	epoller, err = MkEpoll()

	if err != nil {

		panic(err)

	}

	go start()

	for {

		conn, e := ln.Accept()

		if e != nil {

			if ne, ok := e.(net.Error); ok && ne.Temporary() {

				log.Printf("accept temp err: %v", ne)

				continue

			}

			log.Printf("accept err: %v", e)

			return

		}

		if err := epoller.Add(conn); err != nil {

			log.Printf("failed to add connection %v", err)

			conn.Close()

		}

	}

}

func start() {

	var buf = make(\[\]byte, 8)

	for {

		connections, err := epoller.Wait()

		if err != nil {

			log.Printf("failed to epoll wait %v", err)

			continue

		}

		for _, conn := range connections {

			if conn == nil {

				break

			}

			if _, err := conn.Read(buf); err != nil {

				if err := epoller.Remove(conn); err != nil {

					log.Printf("failed to remove %v", err)

				}

				conn.Close()

			}

		}

	}

}
```

`listener`还是保持原来的样子，`Accept`一个新的客户端请求后，就把它加入到epoll的管理中。单独起**一个** gorouting监听数据到来的事件，每次只最多读取100个事件。

epoll的实现如下：
```go
type epoll struct {

	fd          int

	connections map\[int\]net.Conn

	lock        *sync.RWMutex

}

func MkEpoll() (*epoll, error) {

	fd, err := unix.EpollCreate1(0)

	if err != nil {

		return nil, err

	}

	return &epoll{

		fd:          fd,

		lock:        &sync.RWMutex{},

		connections: make(map\[int\]net.Conn),

	}, nil

}

func (e *epoll) Add(conn net.Conn) error {

	// Extract file descriptor associated with the connection

	fd := socketFD(conn)

	err := unix.EpollCtl(e.fd, syscall.EPOLL\_CTL\_ADD, fd, &unix.EpollEvent{Events: unix.POLLIN | unix.POLLHUP, Fd: int32(fd)})

	if err != nil {

		return err

	}

	e.lock.Lock()

	defer e.lock.Unlock()

	e.connections\[fd\] = conn

	if len(e.connections)%100 == 0 {

		log.Printf("total number of connections: %v", len(e.connections))

	}

	return nil

}

func (e *epoll) Remove(conn net.Conn) error {

	fd := socketFD(conn)

	err := unix.EpollCtl(e.fd, syscall.EPOLL\_CTL\_DEL, fd, nil)

	if err != nil {

		return err

	}

	e.lock.Lock()

	defer e.lock.Unlock()

	delete(e.connections, fd)

	if len(e.connections)%100 == 0 {

		log.Printf("total number of connections: %v", len(e.connections))

	}

	return nil

}

func (e *epoll) Wait() (\[\]net.Conn, error) {

	events := make(\[\]unix.EpollEvent, 100)

	n, err := unix.EpollWait(e.fd, events, 100)

	if err != nil {

		return nil, err

	}

	e.lock.RLock()

	defer e.lock.RUnlock()

	var connections \[\]net.Conn

	for i := 0; i < n; i++ {

		conn := e.connections\[int(events\[i\].Fd)\]

		connections = append(connections, conn)

	}

	return connections, nil

}

func socketFD(conn net.Conn) int {

	//tls := reflect.TypeOf(conn.UnderlyingConn()) == reflect.TypeOf(&tls.Conn{})

	// Extract the file descriptor associated with the connection

	//connVal := reflect.Indirect(reflect.ValueOf(conn)).FieldByName("conn").Elem()

	tcpConn := reflect.Indirect(reflect.ValueOf(conn)).FieldByName("conn")

	//if tls {

	//	tcpConn = reflect.Indirect(tcpConn.Elem())

	//}

	fdVal := tcpConn.FieldByName("fd")

	pfdVal := reflect.Indirect(fdVal).FieldByName("pfd")

	return int(pfdVal.FieldByName("Sysfd").Int())

}
```

### 客户端

还是运行上面的客户端，因为刚才已经建立了50个客户端的容器，我们需要先把他们删除：
```bash
docker rm -vf  $(docker ps -a --format '{ {.ID} } { {.Names} }'|grep '1mclient_' |awk '{print $1}')
```
然后再启动50个客户端，每个客户端2万个连接进行进行测试

```bash
./setup.sh 20000 50 172.17.0.1
```
### 数据分析

使用以下工具查看性能：

*   dstat：查看机器的资源占用（cpu， memory，中断数和上下文切换次数）
*   ss：查看网络连接情况
*   pprof：查看服务器的性能
*   report.sh: 后续通过脚本查看延迟

![没连接前的服务器](https://colobu.com/2019/02/23/1m-go-tcp-connection/1-before-start.png)没连接前的服务器  
![建立百万连接后的服务器](https://colobu.com/2019/02/23/1m-go-tcp-connection/2-connected.png "建立百万连接后的服务器")
建立百万连接后的服务器

可以看到建立连接后大约占了10G的内存，CPU占用非常小。

有一个专门使用epoll实现的网络库[tidwall/evio](https://github.com/tidwall/evio),可以专门开发epoll方式的网络程序。去年阿里中间件大赛，美团的王亚普使用evio库杀入到排行榜第五名，也是前五中唯一一个使用Go实现的代码，其它使用Go标准库实现的代码并没有达到6983 tps/s 的程序，这也说明了再一些场景下采用epoll方式也能带来性能的提升。（[天池中间件大赛Golang版Service Mesh思路分享](https://www.jianshu.com/p/cceaaaf5d154)）

但是也正如evio作者所说，evio并不能提到Go标准net库，它只使用特定的场景, 实现redis/haproxy等proxy。因为它是单goroutine处理处理的，或者你可以实现多goroutine的event-loop,但是针对一些I/O或者计算耗时的场景，未必能展现出它的优势出来。

我们知道Redis的实现是单线程的，正如作者[Clarifications about Redis and Memcached](http://antirez.com/news/94)介绍的，Redis主要是内存中的数据操作，单线程根本不是瓶颈(持久化是独立线程)我们后续的测试也会印证这一点。所以epoll I/O dispatcher之后是采用单线程还是Reactor模式(多线程事件处理)还是看具体的业务。

下一篇文章我们会继续测试百万连接情况下的吞吐率和延迟，这是上面的两篇文章所没有提到的。

参考
--

1.  [https://mrotaru.wordpress.com/2013/10/10/scaling-to-12-million-concurrent-connections-how-migratorydata-did-it/](https://mrotaru.wordpress.com/2013/10/10/scaling-to-12-million-concurrent-connections-how-migratorydata-did-it/)
2.  [https://stackoverflow.com/questions/22090229/how-did-whatsapp-achieve-2-million-connections-per-server](https://stackoverflow.com/questions/22090229/how-did-whatsapp-achieve-2-million-connections-per-server)
3.  [https://github.com/eranyanay/1m-go-websockets](https://github.com/eranyanay/1m-go-websockets)
4.  [https://medium.freecodecamp.org/million-websockets-and-go-cc58418460bb](https://medium.freecodecamp.org/million-websockets-and-go-cc58418460bb)

 
