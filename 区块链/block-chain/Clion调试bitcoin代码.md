# Clion调试bitcoin代码（for mac OR Ubuntu16.04）

我使用的是bch的代码，[代码下载地址](https://github.com/Bitcoin-ABC/bitcoin-abc/releases)   我下
载的是0.17.2版本的代码，建议不要用其他版本的代码  因为我也不知道其他的代码会不会有其他的问题

[TOC]

## 第一步，安装Clion 

我使用的是mac平台，首先下载CLion专业版
这里介绍下这个http://xclient.info/免费下载mac软件的地方
[CLion下载链接](http://xclient.info/s/clion.html?a=dl&v=2018.1.3&k=0&t=c0321e621d18b21e2ba8791a627b3f9bc45dd6a9)：
[CLion破解教程](https://www.jianshu.com/p/f404994e2843)

## 第二部安装必要的库

brew install automake berkeley-db libtool --c++11 miniupnpc openssl pkg-config protobuf --c++11 qt5 libevent
（使用brew工具，或者安装brew工具的方法不再叙述，百度上有很多）
其中要安装boost库为 boost1.58 
如果遇到如下错误就是因为boost库版本对不上的原因
```CMake Error at /Users/macos/Documents/code/bitcoin-abc-0.17.2-bch/cmake-build-debug/CMakeFiles/CMakeTmp/CMakeLists.txt:14 (add_executable):
  Target "cmTC_0700b" links to target "Boost::unit_test_framework" but the
  target was not found.  Perhaps a find_package() call is missing for an
  IMPORTED target, or an ALIAS target is missing?

``` 

###### 1.下载boost安装包 

官网下载地址 
https://sourceforge.net/projects/boost/files/boost/1.58.0/ 

###### 2.解压并进入boost_1_58_0文件夹 

这里注意不要把下载的文件放到一个有中文路径的目录下面，而且我们要记住这个路径
>/Users/alphababy/bitcoin

###### 3.执行boostrap.sh

>./boostrap.sh

###### 4.上一步执行成功后会生成b2脚本，执行它 

>./b2

或者直接执行

>./b2 install

###### 5.等待安装完成

###### 6.最后在cmakelist中设置boost库的根路径

> set(BOOST_ROOT "/Users/alphababy/bitcoin/boost_1_58_0")  
                                  
> find_package(Boost 1.58 REQUIRED ${BOOST_PACKAGES_REQUIRED})  

然后Tool》CMake》reload camke project

如果出现了这种错误，就应该是你代码放到了中文目录下面或者代码中出现了中文，仔细检查下就行了

```bash
src/CMakeFiles/bitcoind.dir/build.make:109: *** target pattern contains no `%'.  Stop.
make[2]: *** [src/CMakeFiles/bitcoind.dir/all] Error 2
make[1]: *** [src/CMakeFiles/bitcoind.dir/rule] Error 2
make: *** [bitcoind] Error 2
```

# 和上述步骤一样安装好CLion

然后用CLion打开bitcoin-abc-0.17.2文件夹，按理说最开始就是应该会报错，这些错误都应该是你缺少安装了某些库，下面主要说下载ubuntu的环境中应该安装些什么库

```bash
>sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils

>sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev

>sudo apt-get install libdb-dev

>sudo apt-get install libdb++-dev

>sudo apt-get install libminiupnpc-dev

>sudo apt-get install libzmq3-dev

>sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler

>sudo apt-get install libqt4-dev libprotobuf-dev protobuf-compiler

>sudo apt-get install libqrencode-dev

>sudo apt-get install libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm* libxcb-icccm4-dev libxcb-sync* libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxcb-xinerama0-dev

>echo "deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/ ./" >> /etc/apt/sources.list
wget https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/Debian_9.0/Release.key -O- | sudo apt-key add
apt-get install libzmq3-dev

Menlo, Monaco, 'Courier New', monospace
```