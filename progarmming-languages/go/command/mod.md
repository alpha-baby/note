# 拉取私有仓库依赖包

**1. 是否配置了`GOPRIVATE`环境变量**

例如：例如你拉取的包是：go.example.com/demo/gotool，那么需要 配置 `GOPRIVATE=go.example.com/demo/gotool`

当然，`GOPRIVATE`的匹配规则是默认前缀匹配，如果你私有仓库的包都在某个域名下面，那么以上包为例，也可以这样配置`GOPRIVATE=go.example.com`，那么以后如果你要拉取的包是以`go.example.com`开头的那么依然生效。

**2. 可以先清理下本地mod缓存数据：**

```bash
go clean -modcache
```

以上命令的原理就是删除在`$GOPATH/pkg/mod`目录中的所有文件，你也可以进行手动删除

**3. 首先排查你拉取的拉取的依赖包的版本在私有仓库中是否存在**

例如：你拉取 go.example.com/demo/gotool v1.0.0
首先查看私有git仓库中是否有 v1.0.0 的tag

**4. 虽然你配置了ssh公钥到私有仓库中，但是有时候go mod download 包的时候并不是走的ssh协议，而是http协议**

有两种方法可以解决这个问题：

- 3.1 第一种：配置上这个环境变量：`export GIT_TERMINAL_PROMPT=1`，然后重新下载包

- 3.2 第二种：例如你要拉取的包是：go.example.com/demo/gotool，你可以先`git clone https://go.example.com/demo/gotool.git`,先让git记住你的用户名和密码

如果你是macOS，通过以上操作后，可以到mac的`钥匙串->密码`程序中看到 go.example.com 域名的密码。


>GO MODULE 更多的用法可以参考博客：
>[干货满满的 Go MODULE 和 goproxy.cn](https://eddycjy.com/posts/go/go-moduels/2019-09-29-goproxy-cn/)