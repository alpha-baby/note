# go build 命令使用记录

## go build -tags 说明

>参考 https://www.cnblogs.com/linyihai/p/10859945.html

#### 使用tag来实现编译不同的文件

[go-tooling-workshop 中关于go build的讲解](https://github.com/campoy/go-tooling-workshop/blob/master/2-building-artifacts/1-go-build.md)可以了解到go bulid的一些用法，这篇文章最后要求实现一个根据go bulid -tag功能来编译不同版本的做法，version参数根据tag传进来的值进行编译。下面是一个实例，main.go

```golang
package main

import "fmt"

// HINT: You might need to move this declaration to a different file.
const version = "dev"
func main() {
    fmt.Printf("running %s version", version)
}
```
    

好，新建一个dev_config.go文件，代码如下

```golang
// +build dev

package main

var version = "DEV"
```
    

上面代码的关键是 `// +build dev`这行代码，注意这行代码前后须有一个空行隔开，例如在第一行时，接下来要空出一行。这个文件只会被go bulid识别到，而go run等命令不会去识别这个文件，而且vscode等编辑器也会略过这个文件。  
再新建一个文件release_config.go,代码如下

```golang
// +build release

package main

const version = "RELEASE"
```

代码已经准备完毕，还有一个地方要注意，需要去掉main.go中的`const version = 'dev'`这行代码，否则，go bulid命令会报version重复定义。  
执行命令如下：

```bash
$ go build -tags dev -o dev_version

$ ./dev_version
running DEV version

$ go build -tags release -o release_version

$ ./release_version
running RELEASE version
```

**[完整例子](https://github.com/linyihai/GoTour/blob/master/tools/GoBuildTags/readme.md)**

## go build -ldflags 说明

>参考 https://www.cnblogs.com/linyihai/p/10859945.html

go build还支持通过命令行传递编译参数，通过-ldflags参数实现，将main.go修改为

```golang
package main

import "fmt"

// HINT: You might need to move this declaration to a different file.
var version string

func main() {
    fmt.Printf("running %s version", version)
}
``` 

命令行执行：


```bash
$ go build -ldflags '-X main.version="dev"' -o dev_version

$ ./dev_version
running "dev" version
```

**[完整例子](https://github.com/linyihai/GoTour/blob/master/tools/GoBuildTags/readme.md)**