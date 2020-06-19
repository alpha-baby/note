### 准备活动

首先你得自己搭建了一个代理服务器，如果你还没有搭建好自己的代理服务器，可以参考我的搭建教程。
[Ubuntu16.04搭电路层代理 server及优化](https://www.jianshu.com/p/14f474626914)

然后你还得有一个ss(shadowsocks)客户端, 如果没有可以去下载好。
[github下载](https://github.com/zhoudaxiaa/ss-client)
如果你有客户端，并且还在使用就可以忽略下一步了。

![](https://upload-images.jianshu.io/upload_images/13859457-2951b25726211222.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 终端走代理

 先打开看一下你的客户端代理走的端口是什么。
点击上图中的偏好设置。

![](https://upload-images.jianshu.io/upload_images/13859457-bc886976de27bf28.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

然后后可以看到我们http代理的端口是 `1087`

这步骤的作用是找到你http代理的端口，不通平台的ss客户端看法不一样。windows平台的ss客户端就在服务器设置里面就可以看到，windows客户端一般默认是`1080`端口。

然后我们可以在你想走代理的客户端执行一下命令就可以在某个终端下走代理(也就是科学上网，f墙)。

先检测一下我们没有fan-qiang的效果
>$ curl ip.ps

![](https://upload-images.jianshu.io/upload_images/13859457-83fe6d88281cbd62.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

>$ export http_proxy='127.0.0.1:1087' # 这里的1087就是你客户端开启后走代理的端口


然后我们再检查下，就发现已经代理到国外了哈哈

![](https://upload-images.jianshu.io/upload_images/13859457-c9721ed6913d3351.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

如果不想走代理了就执行如下命令

>$ unset http_proxy

### linux中还有其他的一些代理的变量(本人只在mac的bash中试成功了)
|变量名          | 代理协议             |
|:--                 |:--                         |
|all_proxy      |   代理所有的协议 |
|ftp_proxy     |   代理ftp               |
|https_proxy |   代理https           |
|http_proxy   |  代理http              |

当我们设置好后可以检测

设置代理变量前：一直不能获取到网页

![](https://upload-images.jianshu.io/upload_images/13859457-639b5a4e520b66a6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

当我们设置`all_proxy`后：

![](https://upload-images.jianshu.io/upload_images/13859457-ab3d274ca3ffd214.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们可以根据我们需要代理的协议进行相应的设置但是我一般都用`all_proxy`