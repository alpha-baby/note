
# go1.11之后的大变化

这篇写出来了是为了避免踩坑。
go1.11之后的版本根之前的包管理方式不同，并且项目不再依赖GOPATH，使用了GO module 模式。

go 1.11 有了对模块的实验性支持，大部分的子命令都知道如何处理一个模块，比如 `run` `build` `install` `get` `list` `mod` 子命令，第三方工具可能会支持的晚一些。到 go 1.12 会删除对 `GOPATH` 的支持，`go get` 命令也会变成只能获取模块，不能像现在这样直接获取一个裸包。
可以用环境变量 `GO111MODULE` 开启或关闭模块支持，它有三个可选值：`off`、`on`、`auto`，默认值是 `auto`。

* GO111MODULE=off 无模块支持，go 会从 GOPATH 和 vendor 文件夹寻找包。

* GO111MODULE=on 模块支持，go 会忽略 GOPATH 和 vendor 文件夹，只根据 go.mod 下载依赖。

* GO111MODULE=auto 在 $GOPATH/src 外面且根目录有 go.mod 文件时，开启模块支持。

在使用模块的时候，GOPATH 是无意义的，不过它还是会把下载的依赖储存在 $GOPATH/pkg/mod 中，也会把 go install 的结果放在 $GOPATH/bin 中。

更多go mod 使用 ：[https://www.jianshu.com/p/c5733da150c6](https://www.jianshu.com/p/c5733da150c6)

# 重要区别

go1.11之前的包管理使用的govendor , 是不区分包版本的，意味着开发期间拉的依赖的包很可能跟上线后的拉的依赖包版本不一致，很危险。

go1.11之后，水用go module 模式，解除对GOPATH依赖，使用go get 管理下载依赖包，带版本控制的

# 两个路径

go 安装后要设置两个路径

* `GOPATH` : go1.11之前放项目的地方，go.1.11后不放项目了，是go get 后的依赖包存放的地方

* `GOROOT` : go的安装路径,里面有系统包,如fmt

寻找依赖包的方式:

1,go1.11之前查找顺序

* 项目的vendor目录
* GOPATH/src
* GOROOT/src

2, go1.11之后（设置GO111MODULE=on后）

* GOPATH/pkg/mod
* GOROOT/src

# MacOS golang 环境搭建

以go1.12版本为例

1，安装go1.12

下载地址 [https://golang.google.cn/dl](https://golang.google.cn/dl)

解压即可 /usr/local/go 就是安装路径（GOROOT）

```
tar -C /usr/local -xzf go1.12.darwin-amd64.tar.gz
```

2, 环境变量设置

这段代码放在你的.bash_profile文件中，操作不懂就去查。

```
#设置只支持go module模式
export GO111MODULE=on
#go 安装路径
export GOROOT=/usr/local/Cellar/go/1.12
#go get下载依赖包的路径(go1.11后项目不需要放gopath)
export GOPATH=/Users/Django/www/GOPATH
#方便使用安装小工具如fresh
export PATH=$PATH:${GOPATH//://bin:}/bin
#将go 添加到环境变量
export PATH=$GOROOT/bin:$PATH
#go 代理地址
export GOPROXY=https://goproxy.io
```

# go mod 命令

项目目录下，执行以下命令初始化

```
$ go mod init
```

执行以下命令会自动分析项目里的依赖关系同步到go.mod文件中，同时创建go.sum文件

```
$ go mod tidy
```

以上的管理依赖管理操作，所以依赖包还是在GOPATH/src目录下，go module 当然可以把包直接放在当前项目中管理

```
$ go mod vendor
```

直接使用这个命令就可以把GOPATH/src目录下的依赖包同步到当前项目目录中




> 转载
> [go1.12 go module 入门](http://www.lesscode.fun/2019/03/07/go1-12-module-%E4%BD%BF%E7%94%A8%E5%92%8Cgoland%E8%AE%BE%E7%BD%AE/)