# go rpc 入门

**rpc**（Romote Procedure Call，远程过程调用）。相对应的就是**本地过程调用**，在以前最开始接触编程的时候最简单的就是调用一个自己编写的一个函数。这种就叫做**本地过程调用**。

## 本地过程调用

比如以下代码就是本地过程调用。

```go
package main

import "fmt"

func Sum(a, b int) int {
    return a+b
}

func main() {
    fmt.Printf("sum = %d\n", Sum(1, 2))
}
```

在**本地过程调用**中，函数调用的本质是直接拿到函数指针，然后去调用对应的代码段。

## 远程过程调用

远程过程调用跨越了物理服务器的限制，是在网络中完成的，在调用远程服务器的过程中，本地程序等待返回结果，知道远端程序执行完毕，讲结果进行返回到本地，最终完成一次完整的调用。

**远程过程调用指的是调用远端服务器上的程序的方法的整个过程**


### rpc的技术架构

![](https://tva1.sinaimg.cn/large/006tNbRwly1gaw406d7bpj30do08kgmh.jpg)

1. **客户端（client）**：服务调用发起方，又称为服务消费者。
2. **服务器（server）**：远程计算机上运行的程序，其中包含客户端要调用和访问的方法。
3. **客户端存根（client stub）**：存放服务端的地址，端口消息。将客户端的请求参数打包成网络消息，发送到服务方。接受服务方返回的消息。该段程序运行在客户端。
4. **服务端存根（server stub）**：接受客户端发送的数据包，解析数据包，调用具体的服务方法，将调用结果打包成数据包发送给客户端。

![](https://tva1.sinaimg.cn/large/006tNbRwly1gaw3wl9m4xj30hs09ft9j.jpg)

1. 服务消费者（client客户端）通过本地调用的方式调用服务
2. 客户端存根（client stub）接收到调用请求后负责将方法、入参等信息序列化（组装）成能够进行网络传输的消息体
3. 客户端存根（client stub）找到远程的服务地址，并且将消息通过网络发送给服务端
4. 服务端存根（server stub）收到消息后进行解码（反序列化操作）
5. 服务端存根（server stub）根据解码结果调用本地的服务进行相关处理
6. 本地服务执行具体业务逻辑并将处理结果返回给服务端存根（server stub）
7. 服务端存根（server stub）将返回结果重新打包成消息（序列化）并通过网络发送至消费方
8. 客户端存根（client stub）接收到消息，并进行解码（反序列化）
9. 服务消费方得到最终结果

# go rpc 实践

golang是原生支持RPC的，因为官方给我们提供了支持rpc的库：`net/rpc`.
具体链接如下：[https://golang.org/pkg/net/rpc/](https://golang.org/pkg/net/rpc/)。根据官方的解释，rpc包主要是提供通过网络访问一个对象方法的功能。

## 服务端

### 服务定义及暴露

前文我们已经讲过rpc调用有两个参与者，分别是：客户端（client）和服务器（server）。

首先是提供方法暴露的一方--服务器。

在编程实现过程中，服务器端需要注册结构体对象，然后通过对象所属的方法暴露给调用者，从而提供服务，该方法称之为输出方法，此输出方法可以被远程调用。当然，在定义输出方法时，能够被远程调用的方法需要遵循一定的规则。我们通过代码进行讲解：

```go
func (t *T) MethodName(request T1,response *T2) error
```

上述代码是go语言官方给出的对外暴露的服务方法的定义标准，其中包含了主要的几条规则，分别是：

- 1、对外暴露的方法有且只能有两个参数，这个两个参数只能是输出类型或内建类型，两种类型中的一种。
- 2、方法的第二个参数必须是指针类型。
- 3、方法的返回类型为error。
- 4、方法的类型是可输出的。
- 5、方法本身也是可输出的。
我们举例说明：假设目前我们有一个需求，给出一个float类型变量，作为圆形的半径，要求通过RPC调用，返回对应的圆形面积。具体的编程实现思路如下：

```go
// MathUtil 用于数学计算
type MathUtil struct {
}

// CaculateCircleArea 计算圆的面积
func (m *MathUtil) CaculateCircleArea(req float64, resp *float64) error {
	*resp = math.Pi * req * req
	return nil
}
```

在上述的案例中，我们可以看到：

- 1、CaculateCircleArea方法是服务对象MathUtil向外提供的服务方法，该方法用于接收传入的圆形半径数据，计算圆形面积并返回。
- 2、第一个参数req代表的是调用者（client）传递提供的参数。
- 3、第二个参数resp代表要返回给调用者的计算结果，必须是指针类型。
- 4、正常情况下，方法的返回值为是error，为nil。如果遇到异常或特殊情况，则error将作为一个字符串返回给调用者，此时，resp参数就不会再返回给调用者。

至此为止，已经实现了服务端的功能定义，接下来就是让服务代码生效，需要将服务进行注册，并启动请求处理。

### 注册服务及监听请求

net/rpc包为我们提供了注册服务和处理请求的一系列方法，如下所示：

```go
func main() {
	// 创建计算实例
	mathUtil := new(MathUtil)

	// 将对象注册到rpc服务中
	err := rpc.Register(mathUtil)
	if err != nil {
		log.Panic(err)
		return
	}

	//3、通过该函数把mathUtil中提供的服务注册到HTTP协议上，方便调用者可以利用http的方式进行数据传递
	rpc.HandleHTTP()

	//4、在特定的端口进行监听
	listen, err := net.Listen("tcp", ":8081")
	if err != nil {
		panic(err.Error())
	}
	go http.Serve(listen, nil)
}
```

经过服务注册和监听处理，RPC调用过程中的服务端实现就已经完成了。接下来需要实现的是客户端请求代码的实现。

代码：

```go
package main

import (
	"log"
	"math"
	"net"
	"net/http"
	"net/rpc"
)

// MathUtil 用于数学计算
type MathUtil struct {
}

// CaculateCircleArea 计算圆的面积
func (m *MathUtil) CaculateCircleArea(req float64, resp *float64) error {
	*resp = math.Pi * req * req
	return nil
}

func main() {
	// 创建计算实例
	mathUtil := new(MathUtil)

	// 将对象注册到rpc服务中
	err := rpc.Register(mathUtil)
	if err != nil {
		log.Panic(err)
		return
	}

	//3、通过该函数把mathUtil中提供的服务注册到HTTP协议上，方便调用者可以利用http的方式进行数据传递
	rpc.HandleHTTP()

	//4、在特定的端口进行监听
	listen, err := net.Listen("tcp", ":8081")
	if err != nil {
		panic(err.Error())
	}
	http.Serve(listen, nil)
}
```


## 客户端

在服务端是通过Http的端口监听方式等待连接的，因此在客户端就需要通过http连接，首先与服务端实现连接。

1. 客户端连接服务端
```go
client, err := rpc.DialHTTP("tcp", "localhost:8081")
	if err != nil {
		panic(err.Error())
	}
```
2. 远端方法调用 客户端成功连接服务端以后，就可以通过方法调用调用服务端的方法，具体调用方法如下：
```go
var req float64 //请求值
req = 3

var resp *float64 //返回值
err = client.Call("MathUtil.CalculateCircleArea", req, &resp)
if err != nil {
	panic(err.Error())
}
fmt.Println(*resp)
```

上述的调用方法核心在于client.Call方法的调用，该方法有三个参数，第一个参数表示要调用的远端服务的方法名，第二个参数是调用时要传入的参数，第三个参数是调用要接收的返回值。 上述的Call方法调用实现的方式是同步的调用，除此之外，还有一种异步的方式可以实现调用。异步调用代码实现如下：

```go
var req float64 = 3.0
var respSync *float64
//异步的调用方式
syncCall := client.Go("MathUtil.CalculateCircleArea", req, &respSync, nil)
replayDone := <-syncCall.Done
fmt.Println(replayDone)
fmt.Println(*respSync)
```

**replayDone**打印的结果是：`&{MathUtil.CalculateCircleArea 3 0xc0000fe030 <nil> 0xc0000f6420}`

其本质就是`call`结构体：

```go
type Call struct {
	ServiceMethod string      // The name of the service and method to call.
	Args          interface{} // The argument to the function (*struct).
	Reply         interface{} // The reply from the function (*struct).
	Error         error       // After completion, the error status.
	Done          chan *Call  // Strobes when call is complete.
}
```

**syncCall.Done**就是`client.Go`第三个传入的`channel`，但是如果传入的是空则会新建一个。


## 多参数的调用

文件结构如下：
```zsh
.
├── client.go
├── param
│   └── param.go
└── server.go
```

```go
// param/param.go
package param

type Param struct {
	Num1 float64
	Num2 float64
}
```

在`server.go`中添加如下函数

```go
// CalculateSum 计算和
func (m *MathUtil) CalculateSum(req param.Param, resp *float64) error {
	*resp = req.Num1 + req.Num2
	return nil
}
```

修改`client.go`:

```go
package main

import (
	"fmt"
	"RpcCode_mul/param"
	"net/rpc"
)

func main() {
	client, err := rpc.DialHTTP("tcp", "localhost:8081")
	if err != nil {
		panic(err.Error())
	}


	req := param.Param{
		Num1: 1,
		Num2: 3,
	}
	var respSync *float64
	//异步的调用方式
	syncCall := client.Go("MathUtil.CalculateSum", req, &respSync, nil)
	replayDone := <-syncCall.Done
	fmt.Println(replayDone)
	fmt.Println(*respSync)
}
```


