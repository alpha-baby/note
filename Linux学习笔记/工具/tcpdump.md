原文：[https://www.jianshu.com/p/8d9accf1d2f1](https://www.jianshu.com/p/8d9accf1d2f1)

[聊聊 tcpdump 与 Wireshark 抓包分析](https://link.jianshu.com?t=http://mp.weixin.qq.com/s?__biz=MzAxODI5ODMwOA==&mid=2666539134&idx=1&sn=5166f0aac718685382c0aa1cb5dbca45&scene=5&srcid=0527iHXDsFlkjBlkxHbM2S3E#rd)   

**1 起因**  

前段时间，一直在调线上的一个问题：线上应用接受POST请求，请求body中的参数获取不全，存在丢失的状况。这个问题是偶发性的，大概发生的几率为5%-10%左右，这个概率已经相当高了。在排查问题的过程中使用到了tcpdump和Wireshark进行抓包分析。感觉这两个工具搭配起来干活，非常完美。所有的网络传输在这两个工具搭配下，都无处遁形。

为了更好、更顺手地能够用好这两个工具，特整理本篇文章，希望也能给大家带来收获。为大家之后排查问题，添一利器。

**2 tcpdump与Wireshark介绍**

在网络问题的调试中，tcpdump应该说是一个必不可少的工具，和大部分linux下优秀工具一样，它的特点就是简单而强大。它是基于Unix系统的命令行式的数据包嗅探工具，可以抓取流动在网卡上的数据包。

默认情况下，tcpdump不会抓取本机内部通讯的报文。根据网络协议栈的规定，对于报文，即使是目的地是本机，也需要经过本机的网络协议层，所以本机通讯肯定是通过API进入了内核，并且完成了路由选择。【比如本机的TCP通信，也必须要socket通信的基本要素：src ip port dst ip port】

如果要使用tcpdump抓取其他主机MAC地址的数据包，必须开启网卡混杂模式，所谓混杂模式，用最简单的语言就是让网卡抓取任何经过它的数据包，不管这个数据包是不是发给它或者是它发出的。一般而言，Unix不会让普通用户设置混杂模式，因为这样可以看到别人的信息，比如telnet的用户名和密码，这样会引起一些安全上的问题，所以只有root用户可以开启混杂模式，开启混杂模式的命令是：ifconfig en0 promisc, en0是你要打开混杂模式的网卡。

Linux抓包原理：

Linux抓包是通过注册一种虚拟的底层网络协议来完成对网络报文(准确的说是网络设备)消息的处理权。当网卡接收到一个网络报文之后，它会遍历系统中所有已经注册的网络协议，例如以太网协议、x25协议处理模块来尝试进行报文的解析处理，这一点和一些文件系统的挂载相似，就是让系统中所有的已经注册的文件系统来进行尝试挂载，如果哪一个认为自己可以处理，那么就完成挂载。

当抓包模块把自己伪装成一个网络协议的时候，系统在收到报文的时候就会给这个伪协议一次机会，让它来对网卡收到的报文进行一次处理，此时该模块就会趁机对报文进行窥探，也就是把这个报文完完整整的复制一份，假装是自己接收到的报文，汇报给抓包模块。

Wireshark是一个网络协议检测工具，支持Windows平台、Unix平台、Mac平台，一般只在图形界面平台下使用Wireshark，如果是Linux的话，直接使用tcpdump了，因为一般而言Linux都自带的tcpdump，或者用tcpdump抓包以后用Wireshark打开分析。

在Mac平台下，Wireshark通过WinPcap进行抓包，封装的很好，使用起来很方便，可以很容易的制定抓包过滤器或者显示过滤器，具体简单使用下面会介绍。Wireshark是一个免费的工具，只要google一下就能很容易找到下载的地方。

所以，tcpdump是用来抓取数据非常方便，Wireshark则是用于分析抓取到的数据比较方便。

**3 tcpdump使用**

**3.1 语法**

类型的关键字

host(缺省类型): 指明一台主机，如：host 210.27.48.2

net: 指明一个网络地址，如：net 202.0.0.0

port: 指明端口号，如：port 23

确定方向的关键字

src: src 210.27.48.2, IP包源地址是210.27.48.2

dst: dst net 202.0.0.0, 目标网络地址是202.0.0.0

dst or src(缺省值)

dst and src

协议的关键字：缺省值是监听所有协议的信息包

fddi

ip

arp

rarp

tcp

udp

其他关键字

gateway

broadcast

less

greater

常用表达式：多条件时可以用括号，但是要用转义

非 : ! or “not” (去掉双引号)

且 : && or “and”

或 : || or “or”

**3.2 选项**

![](upload-images.jianshu.io/upload_images/1760830-950d6bf9284a2764?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

**3.3 命令实践**

1、直接启动tcpdump，将抓取所有经过第一个网络接口上的数据包

![](https://upload-images.jianshu.io/upload_images/1760830-10a5fe6a2b409639?imageMogr2/auto-orient/strip%7CimageView2/2/w/619/format/webp)

2、抓取所有经过指定网络接口上的数据包

![](https://upload-images.jianshu.io/upload_images/1760830-2cb28ab2fcd74ed9?imageMogr2/auto-orient/strip%7CimageView2/2/w/620/format/webp)

3、抓取所有经过 en0，目的或源地址是 10.37.63.255 的网络数据：

![](https://upload-images.jianshu.io/upload_images/1760830-53394a32746b0aa6?imageMogr2/auto-orient/strip%7CimageView2/2/w/619/format/webp)

4、抓取主机10.37.63.255和主机10.37.63.61或10.37.63.95的通信：

![](https://upload-images.jianshu.io/upload_images/1760830-c8857c1eeb986680?imageMogr2/auto-orient/strip%7CimageView2/2/w/617/format/webp)

5、抓取主机192.168.13.210除了和主机10.37.63.61之外所有主机通信的数据包：

![](https://upload-images.jianshu.io/upload_images/1760830-b916aa7bed3975a5?imageMogr2/auto-orient/strip%7CimageView2/2/w/617/format/webp)

6、抓取主机10.37.63.255除了和主机10.37.63.61之外所有主机通信的ip包

![](https://upload-images.jianshu.io/upload_images/1760830-13e3dff22c02a0a6?imageMogr2/auto-orient/strip%7CimageView2/2/w/620/format/webp)

7、抓取主机10.37.63.3发送的所有数据：

![](https://upload-images.jianshu.io/upload_images/1760830-0fb496cb78e668a5?imageMogr2/auto-orient/strip%7CimageView2/2/w/615/format/webp)

8、抓取主机10.37.63.3接收的所有数据：

![](https://upload-images.jianshu.io/upload_images/1760830-694dae47f466f05a?imageMogr2/auto-orient/strip%7CimageView2/2/w/618/format/webp)

9、抓取主机10.37.63.3所有在TCP 80端口的数据包：

![](https://upload-images.jianshu.io/upload_images/1760830-8d6ec1c12b8c6aa7?imageMogr2/auto-orient/strip%7CimageView2/2/w/615/format/webp)

10、抓取HTTP主机10.37.63.3在80端口接收到的数据包：

![](https://upload-images.jianshu.io/upload_images/1760830-35ae48819ad3cba0?imageMogr2/auto-orient/strip%7CimageView2/2/w/621/format/webp)

11、抓取所有经过 en0，目的或源端口是 25 的网络数据

![](https://upload-images.jianshu.io/upload_images/1760830-3f1a2d805d9a0d9d?imageMogr2/auto-orient/strip%7CimageView2/2/w/616/format/webp)

12、抓取所有经过 en0，网络是 192.168上的数据包

![](https://upload-images.jianshu.io/upload_images/1760830-a318caf3b6b3b390?imageMogr2/auto-orient/strip%7CimageView2/2/w/621/format/webp)

13、协议过滤

![](https://upload-images.jianshu.io/upload_images/1760830-de9bb29486cfcf79?imageMogr2/auto-orient/strip%7CimageView2/2/w/615/format/webp)

14、抓取所有经过 en0，目的地址是 192.168.1.254 或 192.168.1.200 端口是 80 的 TCP 数据

![](https://upload-images.jianshu.io/upload_images/1760830-662a97bbd8c6ae8f?imageMogr2/auto-orient/strip%7CimageView2/2/w/616/format/webp)

15、抓取所有经过 en0，目标 MAC 地址是 00:01:02:03:04:05 的 ICMP 数据

![](https://upload-images.jianshu.io/upload_images/1760830-d708b85ed38e88a1?imageMogr2/auto-orient/strip%7CimageView2/2/w/618/format/webp)

16、抓取所有经过 en0，目的网络是 192.168，但目的主机不是 192.168.1.200 的 TCP 数据

![](https://upload-images.jianshu.io/upload_images/1760830-1033426039c9a96b?imageMogr2/auto-orient/strip%7CimageView2/2/w/620/format/webp)

17、只抓 SYN 包

![](https://upload-images.jianshu.io/upload_images/1760830-a2aa7b97a2bc4199?imageMogr2/auto-orient/strip%7CimageView2/2/w/616/format/webp)

18、抓 SYN, ACK

![](https://upload-images.jianshu.io/upload_images/1760830-49a8ba74ff387de5?imageMogr2/auto-orient/strip%7CimageView2/2/w/618/format/webp)

19、抓 SMTP 数据，抓取数据区开始为”MAIL”的包，”MAIL”的十六进制为 0x4d41494c

![](https://upload-images.jianshu.io/upload_images/1760830-1b67220077f2403a?imageMogr2/auto-orient/strip%7CimageView2/2/w/619/format/webp)

20、抓 HTTP GET 数据，”GET “的十六进制是 0x47455420

![](https://upload-images.jianshu.io/upload_images/1760830-b45b3c6e0eb66096?imageMogr2/auto-orient/strip%7CimageView2/2/w/622/format/webp)

21、抓 SSH 返回，”SSH-“的十六进制是 0x5353482D

![](https://upload-images.jianshu.io/upload_images/1760830-3bebe09048f33f68?imageMogr2/auto-orient/strip%7CimageView2/2/w/620/format/webp)

22、高级包头过滤如前两个的包头过滤，首先了解如何从包头过滤信息：

![](https://upload-images.jianshu.io/upload_images/1760830-39fc1adff79d4b26?imageMogr2/auto-orient/strip%7CimageView2/2/w/625/format/webp)

23、抓 DNS 请求数据

![](https://upload-images.jianshu.io/upload_images/1760830-638593725ad537dd?imageMogr2/auto-orient/strip%7CimageView2/2/w/619/format/webp)

24、其他-c 参数对于运维人员来说也比较常用，因为流量比较大的服务器，靠人工 CTRL+C 还是抓的太多，于是可以用-c 参数指定抓多少个包。

![](https://upload-images.jianshu.io/upload_images/1760830-9054e35fb62d5cb0?imageMogr2/auto-orient/strip%7CimageView2/2/w/618/format/webp)

**3.4 抓个网站练练**

想抓取访问某个网站时的网络数据。比如网站 http://www.baidu.com/ 怎么做？

1、通过tcpdump截获主机www.baidu.com发送与接收所有的数据包

![](https://upload-images.jianshu.io/upload_images/1760830-3840b1aef0b99149?imageMogr2/auto-orient/strip%7CimageView2/2/w/626/format/webp)

2、访问这个网站

![](https://upload-images.jianshu.io/upload_images/1760830-018502077b7180cb?imageMogr2/auto-orient/strip%7CimageView2/2/w/593/format/webp)

3、想要看到详细的http报文。怎么做？

![](https://upload-images.jianshu.io/upload_images/1760830-660a1d85376bc733?imageMogr2/auto-orient/strip%7CimageView2/2/w/596/format/webp)

4、分析抓取到的报文

![](https://upload-images.jianshu.io/upload_images/1760830-d27d840ceb8f597d?imageMogr2/auto-orient/strip%7CimageView2/2/w/591/format/webp)

**4 tcpdump抓取TCP包分析**

TCP传输控制协议是面向连接的可靠的传输层协议，在进行数据传输之前，需要在传输数据的两端（客户端和服务器端）创建一个连接，这个连接由一对插口地址唯一标识，即是在IP报文首部的源IP地址、目的IP地址，以及TCP数据报首部的源端口地址和目的端口地址。TCP首部结构如下：

![](https://upload-images.jianshu.io/upload_images/1760830-e18fbb8480375fcd?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

注意：通常情况下，一个正常的TCP连接，都会有三个阶段:1、TCP三次握手;2、数据传送;3、TCP四次挥手

其中在TCP连接和断开连接过程中的关键部分如下：

源端口号：即发送方的端口号，在TCP连接过程中，对于客户端，端口号往往由内核分配，无需进程指定；

目的端口号：即发送目的的端口号；

序号：即为发送的数据段首个字节的序号；

确认序号：在收到对方发来的数据报，发送确认时期待对方下一次发送的数据序号；

SYN：同步序列编号，Synchronize Sequence Numbers；

ACK：确认编号，Acknowledgement Number；

FIN：结束标志，FINish；

**4.1 TCP三次握手**

三次握手的过程如下：

![](https://upload-images.jianshu.io/upload_images/1760830-0ffbaff453971adc?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

step1. 由客户端向服务器端发起TCP连接请求。Client发送：同步序列编号SYN置为1，发送序号Seq为一个随机数，这里假设为X，确认序号ACK置为0；

step2. 服务器端接收到连接请求。Server响应：同步序列编号SYN置为1，并将确认序号ACK置为X+1，然后生成一个随机数Y作为发送序号Seq（因为所确认的数据报的确认序号未初始化）；

step3. 客户端对接收到的确认进行确认。Client发送：将确认序号ACK置为Y+1，然后将发送序号Seq置为X+1（即为接收到的数据报的确认序号）；

为什么是三次握手而不是两次对于step3的作用，假设一种情况，客户端A向服务器B发送一个连接请求数据报，然后这个数据报在网络中滞留导致其迟到了，虽然迟到了，但是服务器仍然会接收并发回一个确认数据报。但是A却因为久久收不到B的确认而将发送的请求连接置为失效，等到一段时间后，接到B发送过来的确认，A认为自己现在没有发送连接，而B却一直以为连接成功了，于是一直在等待A的动作，而A将不会有任何的动作了。这会导致服务器资源白白浪费掉了，因此，两次握手是不行的，因此需要再加上一次，对B发过来的确认再进行一次确认，即确认这次连接是有效的，从而建立连接。

对于双方，发送序号的初始化为何值有的系统中是显式的初始化序号是0，但是这种已知的初始化值是非常危险的，因为这会使得一些黑客钻漏洞，发送一些数据报来破坏连接。因此，初始化序号因为取随机数会更好一些，并且是越随机越安全。

tcpdump抓TCP三次握手抓包分析：

sudotcpdump-n-S-ilo0host10.37.63.3andtcpport8080

\# 接着再运行：

curlhttp://10.37.63.3:8080/atbg/doc

控制台输出：

![](https://upload-images.jianshu.io/upload_images/1760830-76e3c0d065f35b35?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

每一行中间都有这个包所携带的标志：

S=SYN，发起连接标志。

P=PUSH，传送数据标志。

F=FIN，关闭连接标志。

ack，表示确认包。

RST=RESET，异常关闭连接。

.，表示没有任何标志。

第1行：16:00:13.486776，从10.37.63.3（client）的临时端口61725向10.37.63.3（server）的8080监听端口发起连接，client初始包序号seq为1944916150，滑动窗口大小为65535字节（滑动窗口即tcp接收缓冲区的大小，用于tcp拥塞控制），mss大小为16344（即可接收的最大包长度，通常为MTU减40字节，IP头和TCP头各20字节）。【seq=1944916150，ack=0，syn=1】

第2行：16:00:13.486850，server响应连接，同时带上第一个包的ack信息，为client端的初始包序号seq加1，即1944916151，即server端下次等待接受这个包序号的包，用于tcp字节流的顺序控制。Server端的初始包序号seq为1119565918，mss也是16344。【seq=1119565918，ack=1944916151，syn=1】

第3行：15:46:13.084161，client再次发送确认连接，tcp连接三次握手完成，等待传输数据包。【ack=1119565919，seq=1944916151】

**4.2 TCP四次挥手**

连接双方在完成数据传输之后就需要断开连接。由于TCP连接是属于全双工的，即连接双方可以在一条TCP连接上互相传输数据，因此在断开时存在一个半关闭状态，即有有一方失去发送数据的能力，却还能接收数据。因此，断开连接需要分为四次。主要过程如下：

![](https://upload-images.jianshu.io/upload_images/1760830-c6ef952d1e5b9eef?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

step1. 主机A向主机B发起断开连接请求，之后主机A进入FIN-WAIT-1状态；

step2. 主机B收到主机A的请求后，向主机A发回确认，然后进入CLOSE-WAIT状态；

step3. 主机A收到B的确认之后，进入FIN-WAIT-2状态，此时便是半关闭状态，即主机A失去发送能力，但是主机B却还能向A发送数据，并且A可以接收数据。此时主机B占主导位置了，如果需要继续关闭则需要主机B来操作了；

step4. 主机B向A发出断开连接请求，然后进入LAST-ACK状态；

step5. 主机A接收到请求后发送确认，进入TIME-WAIT状态，等待2MSL之后进入CLOSED状态，而主机B则在接受到确认后进入CLOSED状态；

为何主机A在发送了最后的确认后没有进入CLOSED状态，反而进入了一个等待2MSL的TIME-WAIT主要作用有两个：

第一，确保主机A最后发送的确认能够到达主机B。如果处于LAST-ACK状态的主机B一直收不到来自主机A的确认，它会重传断开连接请求，然后主机A就可以有足够的时间去再次发送确认。但是这也只能尽最大力量来确保能够正常断开，如果主机A的确认总是在网络中滞留失效，从而超过了2MSL，最后也无法正常断开；

第二，如果主机A在发送了确认之后立即进入CLOSED状态。假设之后主机A再次向主机B发送一条连接请求，而这条连接请求比之前的确认报文更早地到达主机B，则会使得主机B以为这条连接请求是在旧的连接中A发出的报文，并不看成是一条新的连接请求了，即使得这个连接请求失效了，增加2MSL的时间可以使得这个失效的连接请求报文作废，这样才不影响下次新的连接请求中出现失效的连接请求。

为什么断开连接请求报文只有三个，而不是四个因为在TCP连接过程中，确认的发送有一个延时（即经受延时的确认），一端在发送确认的时候将等待一段时间，如果自己在这段事件内也有数据要发送，就跟确认一起发送，如果没有，则确认单独发送。而我们的抓包实验中，由服务器端先断开连接，之后客户端在确认的延迟时间内，也有请求断开连接需要发送，于是就与上次确认一起发送，因此就只有三个数据报了。

**5 Wireshark分析tcpdump抓包结果**

1、启动8080端口，tcpdump抓包命令如下：

tcpdump-ilo0-s0-n-Shost10.37.63.3andport8080-w./Desktop/tcpdump\_10.37.63.3\_8080_20160525.cap

\# 然后再执行curl

curlhttp://10.37.63.3:8080/atbg/doc

2、使用Wireshark打开tcpdump\_10.37.63.3\_8080_20160525.cap文件

![](https://upload-images.jianshu.io/upload_images/1760830-0b751dc2d491f2d0?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

No. 1-4 行：TCP三次握手环节；

No. 5-8 行：TCP传输数据环节；

No. 9-13 行：TCP四次挥手环节；

3、顺便说一个查看 http 请求和响应的方法：

![](https://upload-images.jianshu.io/upload_images/1760830-28e55812cd2d29de?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

弹窗如下图所示，上面红色部分为请求信息，下面蓝色部分为响应信息：

![](https://upload-images.jianshu.io/upload_images/1760830-8c7a2a24f08374fc?imageMogr2/auto-orient/strip%7CimageView2/2/w/640/format/webp)

以上是Wireshark分析tcpdump的简单使用，Wireshark更强大的是过滤器工具，大家可以自行去多研究学习Wireshark，用起来还是比较爽的。

推荐几个关于Wireshark的文章：

[Wireshark基本介绍和学习TCP三次握手](https://link.jianshu.com?t=http://mp.weixin.qq.com/s?__biz=MzAxODI5ODMwOA==&mid=2666539095&idx=1&sn=df0f89db06cc3051b6abcbc736fa965e&scene=21#wechat_redirect)

一站式学习Wireshark