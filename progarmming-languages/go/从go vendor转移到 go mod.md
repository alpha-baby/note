# 从go vendor 转移 go mod 到

# 首先我们要知道go mod的工作机制

## 必须知道的环境变量

go 1.11 有了对模块的实验性支持，大部分的子命令都知道如何处理一个模块，比如 `run` `build` `install` `get` `list` `mod` 子命令，第三方工具可能会支持的晚一些。到 go 1.12 会删除对 `GOPATH` 的支持，`go get` 命令也会变成只能获取模块，不能像现在这样直接获取一个裸包。
可以用环境变量 `GO111MODULE` 开启或关闭模块支持，它有三个可选值：`off`、`on`、`auto`，默认值是 `auto`。

* GO111MODULE=off 无模块支持，go 会从 GOPATH 和 vendor 文件夹寻找包。

* GO111MODULE=on 模块支持，go 会忽略 GOPATH 和 vendor 文件夹，只根据 go.mod 下载依赖。

* GO111MODULE=auto 在 $GOPATH/src 外面且根目录有 go.mod 文件时，开启模块支持。

在使用模块的时候，GOPATH 是无意义的，不过它还是会把下载的依赖储存在 $GOPATH/pkg/mod 中，也会把 go install 的结果放在 $GOPATH/bin 中。

更多go mod 使用 ：[https://www.jianshu.com/p/c5733da150c6](https://www.jianshu.com/p/c5733da150c6)

## 我创建了这样一个Demo程序

```
 ~/Desktop/gotest
╰─$ tree
.
├── main.go
└── test
    └── hello.go
```

```
// main.go
package main

import (
	"gotest/test"
)

func main() {
	test.Hello()
}
```

```
// test/hello.go
package test

import "fmt"

func Hello() {
	fmt.Println("hello")
}
```

我的这个demo程序并没有在`GOPATH`下，然后我们就可以使用 `$ go mod projectName` projectName 是你的项目名称，这里我的项目名称是 `gotest`。

```
~/Desktop/gotest
╰─$ go mod init gotest
go: creating new go.mod: module gotest
```

执行完了以后我们目录下就生成了一个文件 

// go.mod
```
module gotest

go 1.12
``` 

接着执行

```
$ go mod tidy
```

这个命令的作用是：执行以下命令会自动分析项目里的依赖关系同步到`go.mod`文件中，同时创建`go.sum`文件。但是这里我并没有用到第三方的包所以并没有生成`go.sum`文件.

> 总结
> 以前使用vendor管理的使用我们必须包项目放到`gopath`下,我们在import 包的时候都是从`$GOPATH/src` 开始导入。
> 到了go mod管管理的时候就可以直接 import "projectName/package"
> 上面我距离中的那个Demo程序的`projectName`就是`gotest`
> 
> 这里我们要知道的是当我们用`go mod`来管理包以后导入包的机制就发生了变化。


# 迁移 vendor 到 mod

如果我们以前项目是用的vendor如果要换成go mod 来管理包的话就直接把 项目中的 `Gopak.*` 文件删除，`vendor` 删除。再把项目中自己写的包文件的improt 改过来。在我的那个Demo中 我写了一个`test`包，就得把 import 的内容改为 "gotest/test"。

然后执行 

```
$ go mod init 加上你项目的名字
```

然后在执行下面的命令拉取依赖包

```
$ go mod tidy
```

在拉取的时候可能遇到golang.org的包就会出现网络错误，这里可以这样解决。

```
$ GOPROXY=https://athens.azurefd.net
```

这样可以配置一个代理，go mod在下载包的时候就不会出现网络错误了。

当包下载完了以后就可以编译了。

但是还可能出现：`ambiguous import`

![](https://upload-images.jianshu.io/upload_images/13859457-f4c075964d68a64c.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

解决办法：

https://github.com/gin-gonic/gin/issues/1673#issuecomment-482023570

>更多命令
```
go mod init:初始化modules
go mod download:下载modules到本地cache
go mod edit:编辑go.mod文件，选项有-json、-require和-exclude，可以使用帮助go help mod edit
go mod graph:以文本模式打印模块需求图
go mod tidy:检查，删除错误或者不使用的modules，下载没download的package
go mod vendor:生成vendor目录
go mod verify:验证依赖是否正确
go mod why：查找依赖

go test    执行一下，自动导包

go list -m  主模块的打印路径
go list -m -f={{.Dir}}  print主模块的根目录
go list -m all  查看当前的依赖和版本信息
```

> 参考
> [用 golang 1.11 module 做项目版本管理](https://www.jianshu.com/p/c5733da150c6)