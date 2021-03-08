# mosn 热更新

> 参考资料
> [官网-MOSN 平滑升级原理解析](https://mosn.io/docs/concept/smooth-upgrade/)
> [github-issue](https://github.com/mosn/mosn/issues/866)
> [博文-tcp链接迁移](https://zhuanlan.zhihu.com/p/97340154)
> [博文-Nginx vs Envoy vs Mosn 平滑升级原理解析](https://ms2008.github.io/2019/12/28/hot-upgrade/)
> [Nginx热升级流程，看这篇就够了](https://www.cnblogs.com/wupeixuan/p/12074007.html)
> [envoy 热重启官方文档说明](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart.html?highlight=hot)|[中文版](https://www.servicemesher.com/envoy/intro/arch_overview/hot_restart.html)

## 1. 思考

在 http 应用程序重启时，如果我们直接 `kill -9` 使程序退出，然后在启动，会有以下几个问题：

1. 旧的请求未处理完，如果服务端进程直接退出，会造成客户端链接中断（收到 RST）；
2. 新请求打过来，服务还没重启完毕，造成 `connection refused`；
3. 即使是要退出程序，直接 `kill -9` 仍然会让正在处理的请求中断；
4. 新启动的进程可能失败，老进程可能平滑推出失败，新进程可能没有完整启动老进程就停止接受连接不再服务；

这些问题会造成不好的客户体验，严重的甚至影响客户业务。所以，我们需要以一种优雅的方式重启／关闭我们的应用，来达到热启动的效果，即：`Zero Downtime`。

一般情况下，我们是退出旧版本，再启动新版本，总会有时间间隔，时间间隔内的请求怎么办？而且旧版本正在处理请求怎么办？
那么，针对这些问题，在升级应用过程中，我们需要达到如下目的：

1. 旧版本为退出之前，需要先启动新版本；
2. 旧版本继续处理完已经接受的请求，并且不再接受新请求；
3. 新版本接受并处理新请求的方式；
4. 新进程完全启动好了再通知老进程平滑退出；

这样，我们就能实现 `Zero Downtime` 的升级效果。

**为什么要使用热更新？**

1. 保证客户端的无感知

有的人可能以为热升级可能只有server端来完成，其实不是。

比如http1.x协议，可以直接在server端 发送header：`connection: close`[参考](https://blog.csdn.net/qq_25330791/article/details/100180102), 虽然server端断开了tcp连接，但是客户端是一个http协议的实现，在协议层都是直接tcp重连操作的，用户在使用http协议的客户端来说是无感知的。同理http2也可以发送`go away`帧也是可以平滑断链，不影响请求，对用户也是透明的。

但是这就需要客户端实现http协议中关于断链的操作，否则客户端还用此连接发送数据就会造成客户端感知到错误。继续深入思考，在此场景下，因为客户端的优劣不能保证，所以作为服务端也不能主动关闭连接，否则也会造成客户端感知到错误。

## 2. 原理

这里我们讨论的是一个tcp的server程序！通常在代码里面，在启动一个server的时候，最开始都是`listen("IP:PORT")`, 如果这个IP的端口被其他的进程占用了，那么就会报错。

我们需要实现用一个新版本的程序来热升级一个老的程序，前提是老的进程正在一直运行，并且监听了一些端口，如果我们在老版本程序正在运行时，去启动新版本的程序去监听一样的IP和端口，那么新程序是会报错，监听失败。

在类Unix的系统中，有这样一句话`一切皆文件`,其实本质上我们在`listen("IP:PORT")`的过程中，就是进程打开了一个系统文件。
在linux中，不同的进程是可以打开同一个文件的.

### 2. 不同进程打开同一个文件

我们写这样一个demo来测试下，是不是真的可以打开多个文件：

```go
package main

import (
    "fmt"
    "log"
    "os"
    "time"
)

func main() {
    fileName := "/tmp/test.txt"

    file, err := os.OpenFile(fileName, os.O_CREATE|os.O_WRONLY, 0755)
    if err != nil {
        fmt.Println("error", err)
        os.Exit(1)
    }
    defer file.Close()

    fileString := "Today very happy."
    file.Seek(0, 2) // 最后增加
    file.WriteString(fileString)
    //file.Write([]byte(fileString))
    log.Printf("pid: %v", os.Getpid())
    time.Sleep(time.Hour)
}
```

在这里，我们可以分别启动两个进程：

```bash
[root@iZwz957vusqd7tgu3cd2eyZ simple]# lsof -p 18789 # 列出进程号为 18789 打开的文件
COMMAND   PID USER   FD      TYPE DEVICE SIZE/OFF     NODE NAME
simple  18789 root  cwd       DIR  253,1     4096   136309 /root/goTest/build-in/file/simple
simple  18789 root  rtd       DIR  253,1     4096        2 /
simple  18789 root  txt       REG  253,1  1486848   402373 /tmp/go-build086564828/b001/exe/simple
simple  18789 root    0u      CHR  136,0      0t0        3 /dev/pts/0
simple  18789 root    1u      CHR  136,0      0t0        3 /dev/pts/0
simple  18789 root    2u      CHR  136,0      0t0        3 /dev/pts/0
simple  18789 root    3w      REG  253,1       17   402966 /tmp/test.txt # 这里就是我们进程打开的那个文件
simple  18789 root    4u  a_inode    0,9        0     4784 [eventpoll]
simple  18789 root    5r     FIFO    0,8      0t0 65609200 pipe
simple  18789 root    6w     FIFO    0,8      0t0 65609200 pipe
[root@iZwz957vusqd7tgu3cd2eyZ simple]# lsof -p 19062
COMMAND   PID USER   FD      TYPE DEVICE SIZE/OFF     NODE NAME
simple  19062 root  cwd       DIR  253,1     4096   136309 /root/goTest/build-in/file/simple
simple  19062 root  rtd       DIR  253,1     4096        2 /
simple  19062 root  txt       REG  253,1  1486848   402969 /tmp/go-build911441460/b001/exe/simple
simple  19062 root    0u      CHR  136,2      0t0        5 /dev/pts/2
simple  19062 root    1u      CHR  136,2      0t0        5 /dev/pts/2
simple  19062 root    2u      CHR  136,2      0t0        5 /dev/pts/2
simple  19062 root    3w      REG  253,1       34   402966 /tmp/test.txt # 这里就是我们进程打开的那个文件
simple  19062 root    4u  a_inode    0,9        0     4784 [eventpoll]
simple  19062 root    5r     FIFO    0,8      0t0 65610829 pipe
simple  19062 root    6w     FIFO    0,8      0t0 65610829 pipe
[root@iZwz957vusqd7tgu3cd2eyZ simple]# cat /tmp/test.txt 
Today very happy.Today very happy.[root@iZwz957vusqd7tgu3cd2eyZ simple]# 
```

### 2.2 Listener的本质

我们在前面提到，``，本质就是打开一个文件，那我们怎么看到这个文件呢？可以看下面的这个例子：

```go
package main

import (
    "log"
    "net"
)

func main() {
    tAddr, _ := net.ResolveTCPAddr("tcp", "127.0.0.1:0")
    l, _ := net.ListenTCP("tcp", tAddr)
    f, _ := l.File()
    log.Println(f.Fd())
    log.Println(f.Name())
}
```

> 关于系统文件描述符FD，可以参考 [文件描述符fd（File Descriptor）简介](https://juejin.cn/post/6844904005202608136)

在热升级的时候，如果我们在新的进程里面只要打开和老的进程是同一个文件，那么就可以避免监听同一个端口报错的问题了。

### 2.3 打开相同文件

如果我们需要在不同进程中去打开一个socket文件，可以靠Unix操作系统调用 `sendmsg/recvmsg`。

> SCM_RIGHTS - Send or receive a set of open file descriptors from another process. The data portion contains an integer array of the file descriptors. The passed file descriptors behave as though they have been created with dup(2). http://linux.die.net/man/7/unix

在go里面怎么操作呢？，可以看如下例子：

```go
package main

import (
    "fmt"
    "log"
    "net"
    "syscall"
)

func main() {
    tAddr, _ := net.ResolveTCPAddr("tcp", "127.0.0.1:0")
    l, _ := net.ListenTCP("tcp", tAddr)
    f, _ := l.File()
    log.Println(f.Fd())
    log.Println(f.Name())
    rights := syscall.UnixRights(int(f.Fd())) // 输出控制信息
    fmt.Printf("control message: %v\n", rights)
}
```

在go中只要把`syscall.UnixRights`输出的控制信息，发送给其他的进程，其他的进程收到后收再进行解析，就可以打开同样的socket文件了。具体的操作如下：

```go
package main

import (
    "fmt"
    "golang.org/x/sys/unix"
    "log"
    "net"
    "os"
    "syscall"
    "time"
)

func main2() { // 发送 文件描述符等辅助信息
    l, _ := net.Listen("tcp", "127.0.0.1:0")
    tcpL := l.(*net.TCPListener)
    f, _ := tcpL.File()
    log.Println(f.Fd())
    log.Println(f.Name())
    rights := syscall.UnixRights(int(f.Fd()))
    fmt.Printf("control message: %v\n", rights) // sned rights to new process
    time.Sleep(time.Hour)
}

func main() { // 接受 文件描述符等辅助信息
    rights := []byte{} // todo recv rights
    scms, err := unix.ParseSocketControlMessage(rights)
    if err != nil {
        log.Fatalf("[ERROR] ParseSocketControlMessage: %v", err)
    }
    if len(scms) != 1 {
        log.Fatalf("[ERROR] expected 1 SocketControlMessage; got scms = %#v", scms)
    }
    gotFds, err := unix.ParseUnixRights(&scms[0])
    if err != nil {
        log.Fatalf("[ERROR] unix.ParseUnixRights: %v", err)
    }

    var listeners []net.Listener
    for i := 0; i < len(gotFds); i++ {
        fd := uintptr(gotFds[i])
        file := os.NewFile(fd, "")
        if file == nil {
            log.Fatalf("[ERROR] create new file from fd %d failed", fd)
        }
        defer file.Close()

        fileListener, err := net.FileListener(file)
        if err != nil {
            log.Fatalf("[ERROR] recover listener from fd %d failed: %s", fd, err)
        }
        // for tcp or unix listener
        listeners = append(listeners, fileListener)
    }
    time.Sleep(time.Hour)
}
```

## 3. 实现

接下来我们我们再看怎么把文件描述符通过，系统调用的`sendmsg/recvmsg`发送给新进程。

```go
// old process
package main

import (
    "fmt"
    "golang.org/x/sys/unix"
    "log"
    "net"
    "os"
    "syscall"
    "time"
)

func main() { // 发送 文件描述符等辅助信息
    l, _ := net.Listen("tcp", "127.0.0.1:0")
    tcpL := l.(*net.TCPListener)
    f, _ := tcpL.File()
    log.Println(f.Fd())
    log.Println(f.Name())
    rights := syscall.UnixRights(int(f.Fd()))
    fmt.Printf("control message: %v\n", rights)
    // 发送
    var unixConn net.Conn
    var err error
    // retry 10 time
    for i := 0; i < 10; i++ {
        unixConn, err = net.DialTimeout("unix", "/tmp/litener.sock", 1*time.Second)
        if err == nil {
            break
        }
        log.Printf("[INFO] try unix  conn to new process, %v\n", i+1)
        time.Sleep(1 * time.Second)
    }
    if err != nil {
        log.Fatalf("[ERROR] [transfer] [sendInheritListeners] Dial unix failed %v\n", err)
    }

    uc := unixConn.(*net.UnixConn)
    buf := make([]byte, 1)
    log.Printf("[INFO] sendUnixRights: %v\n", rights)
    _, _, err = uc.WriteMsgUnix(buf, rights, nil)
    if err != nil {
        log.Fatalf("[ERROR] [transfer] [sendInheritListeners] WriteMsgUnix error: %v\n", err)
    }
    time.Sleep(time.Hour)
}
```

```go
// new process
package main

import (
    "fmt"
    "golang.org/x/sys/unix"
    "log"
    "net"
    "os"
    "syscall"
    "time"
)

func main() { // 接受 文件描述符等辅助信息
    l, err := net.Listen("unix", "/tmp/litener.sock")
    if err != nil {
        log.Fatalf("[ERROR] InheritListeners net listen error: %v", err)
    }
    defer l.Close()

    log.Printf("[INFO] Get InheritListeners start")

    ul := l.(*net.UnixListener)
    ul.SetDeadline(time.Now().Add(time.Second * 30))
    uc, err := ul.AcceptUnix()
    if err != nil {
        log.Fatalf("[ERROR] InheritListeners Accept error :%v", err)
    }
    log.Printf("[INFO] Get InheritListeners Accept")

    buf := make([]byte, 1)
    rights := make([]byte, 1024)
    _, oobn, _, _, err := uc.ReadMsgUnix(buf, rights)
    if err != nil {
        log.Fatalf("[ERROR] ReadMsgUnix error :%v", err)
    }
    // 解析 文件描述符等信息
    scms, err := unix.ParseSocketControlMessage(rights[:oobn])
    if err != nil {
        log.Fatalf("[ERROR] ParseSocketControlMessage: %v", err)
    }
    if len(scms) != 1 {
        log.Fatalf("[ERROR] expected 1 SocketControlMessage; got scms = %#v", scms)
    }
    gotFds, err := unix.ParseUnixRights(&scms[0])
    if err != nil {
        log.Fatalf("[ERROR] unix.ParseUnixRights: %v", err)
    }
    // 通过文件描述符 恢复 listener
    var listeners []net.Listener
    for i := 0; i < len(gotFds); i++ {
        fd := uintptr(gotFds[i])
        file := os.NewFile(fd, "")
        if file == nil {
            log.Fatalf("[ERROR] create new file from fd %d failed", fd)
        }
        defer file.Close()

        fileListener, err := net.FileListener(file)
        if err != nil {
            log.Fatalf("[ERROR] recover listener from fd %d failed: %s", fd, err)
        }
        log.Printf("build listener success: addr: %v\n", fileListener.Addr())
        // for tcp or unix listener
        listeners = append(listeners, fileListener)
    }

    time.Sleep(time.Hour)
}
```

在这里，因为程序的原因，需要快速的启动两个程序。这里可以看下我再本地执行是什么一个效果：

```bash
$ go run . # new process
2021/01/27 10:27:17 [INFO] Get InheritListeners start
2021/01/27 10:27:29 [INFO] Get InheritListeners Accept
2021/01/27 10:27:29 build listener success: addr: 127.0.0.1:55906
...
```

```bash
$ go run . # old process
2021/01/27 10:27:29 5
2021/01/27 10:27:29 tcp:127.0.0.1:55906->
control message: [16 0 0 0 255 255 0 0 1 0 0 0 5 0 0 0]
2021/01/27 10:27:29 [INFO] sendUnixRights: [16 0 0 0 255 255 0 0 1 0 0 0 5 0 0 0]
...
```

这里我们演示了怎么迁移`TCPListener`的文件，如果要迁移`net.Conn`的文件，同理可得。

一个迁移完整的tcp的过程可以参考如下两个例子：

> https://github.com/alpha-baby/go-tcp
> https://zhuanlan.zhihu.com/p/97340154

两个例子中都是模仿的mosn里面的热升级。如果把以上两个代码都看懂，再去看mosn里面代码就好一点，因为mosn里面很多service mesh的逻辑，如果一上手mosn源码会比较困难。

## 4. 总结

在tcp热升级的过程中本质就是在不同进程中迁移文件描述符等控制信息，其中需要借助操作系统调用来完成。

拓展阅读

> [Golang服务器热重启、热升级、热更新(safe and graceful hot-restart/reload http server)详解](https://www.cnblogs.com/sunsky303/p/9778466.html)
> [gracehttp: 优雅重启 Go 程序（热启动 - Zero Downtime）](https://segmentfault.com/a/1190000015232528)
> [如何用 Go 实现热重启](https://segmentfault.com/a/1190000019790072)
> [源码分析grpc graceful shutdown优雅退出](http://xiaorui.cc/archives/6402)
> [大佬博客文章 Envoy hot restart](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)