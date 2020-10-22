# CPU占用过高的分析思路

[toc]

## 先用`top`命令找出CPU占用比最高的进程

 ![](https://upload-images.jianshu.io/upload_images/13859457-f52982f9930e6463.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

比如我这里可以看到 `etcd` `redis-server`占用是比较高的。

## `ps -ef` 进一步定位，得知是一个怎样的后台程序在占用CPU

![](https://upload-images.jianshu.io/upload_images/13859457-e8b81ce4a9de94fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我这里就找到了这个redis 的进程，进程ID为11089

## 定位到具体的线程或代码

`ps -mp 进程ID -o THREAD,tid,time`

![](https://upload-images.jianshu.io/upload_images/13859457-3acb0145e76daa00.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我这个Demo的例子里面可以看到 `redis-server` 这个进程下面的线程，其中 11089 这个线程占用最多。


## 将线程ID转为16进制格式

上一个步骤我们找到了这个线程的ID为 11089 但是这是十进制的，所以我们要转化为16进制：为0x2b51。

## `jstack 进程ID | grep tid(16进制线程ID) -A60`

> 参考阳哥视频
