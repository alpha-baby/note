# interface{} 的底层原理
Joy  Go后端干货  5月8日
## 编程题：以下Go代码会输出什么？


```go
package main

import "fmt"

type Human interface {
    Say() string
}

type Man struct {
}

func (m *Man) Say() string {
    return "man"
}

func IsNil(h interface{}) bool {
    return h == nil
}

func main() {
    var a interface{}
    var b *Man
    var c *Man
    var d Human
    var e interface{}
    a = b
    e = a
    fmt.Println(a == nil) // (1)
    fmt.Println(e == nil) // (2)
    fmt.Println(a == c)   // (3)
    fmt.Println(a == d)   // (4)
    fmt.Println(c == d)   // (5)
    fmt.Println(e == b)   // (6)
    fmt.Println(IsNil(c)) // (7)
    fmt.Println(IsNil(d)) // (8)
}
```
    这道题考察的是对Go interface的理解，包括空interface（无方法）和带有方法的interface。因为在Go编程中，interface最常用不过了，但是稍有不慎，就会出现一些匪夷所思的bug。

    在揭晓答案之前，我们先不急着去作答，先看完以下的分析再作答也不迟。   



### nil在底层的定义
---
```
var nil Type // Type must be a pointer, channel, func, interface, map, or slice type
nil is a predeclared identifier representing the 
zero value for a pointer, channel, func, interface, map, or slice type.
    从Go的源码注释可以看出，只有pointer，channel，func，interface，map，slice等类型才能赋值为nil，否则会报编译错误。
```

### interface底层结构
---

Go的interface是由两种类型来实现的：iface和eface。


其中，**iface表示的是包含方法的interface**，例如：
```go
type Person interface {
	Speak()
}
```
而**eface表示的是不包含方法的interface**，即
```go
type Person interface {}
```

### `eface`底层分析

`eface`的具体结构是：

![](https://mmbiz.qpic.cn/mmbiz_jpg/DBP3HAicOpFVcSI6EE8kFHdLL9YhmqFwicv4Q0iaoR9KOrmia5ByQwJGia4iaZIf34tEVUM1uDIePmSDqW31Ve6HFtyg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

`eface`一共由两个属性构成，一个是类型信息`_type`，一个是数据信息`data`。

`_type`是描述数据类型的，Go语言中几乎所有的数据结构都可以抽象成`_type`，是所有类型的表现，可以说是万能类型。

`data`是指向具体数据的指针。



### `iface`底层分析

所有包含方法的接口，都会使用iface结构。包含方法的接口就是一下这种最常见，最普通的接口：
```go
type Person interface {
	Speak()
}
```
`iface`的源代码是：
```go
type iface struct {
	tab  *itab
	data unsafe.Pointer
}
```
`iface`的具体结构是：

![](https://mmbiz.qpic.cn/mmbiz_jpg/DBP3HAicOpFVcSI6EE8kFHdLL9YhmqFwic0FPbSlRc05W7k4pCugPrMgCLQXCrp1smeMB8zsATSj9wC7j8GamqyQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

`itab`是`iface`不同于`eface`比较关键的数据结构。其可包含两部分：一部分是确定唯一的包含方法的`interface`的具体结构类型，一部分是指向具体方法集的指针。

`itab`具体结构为：

![](https://mmbiz.qpic.cn/mmbiz_png/DBP3HAicOpFVcSI6EE8kFHdLL9YhmqFwicd7C4FcLZEFK3QM6CayOuEgjqDP7UURI7HFJ9cSI3LjUbDsXh8GgxyA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)


属性`itab`的源代码是：
```go
type itab struct {
	inter *interfacetype //此属性用于定位到具体interface
	_type *_type //此属性用于定位到具体interface
	hash  uint32 // copy of _type.hash. Used for type switches.
	_     [4]byte
	fun   [1]uintptr // variable sized. fun[0]==0 means _type does not implement inter.
}
```

`iface`的整体结构为：

![](https://mmbiz.qpic.cn/mmbiz_jpg/DBP3HAicOpFVcSI6EE8kFHdLL9YhmqFwicn4E9kxOex4VOHthXQVnDQRgN4AH9cK5SgB9FFQvpBh9BLLWLGlWlXQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### interface何时才为nil？

`eface`：当`_type`和`data`都为`nil`的时候。

`iface`：当`itab`和`data`都为`nil`的时候。



### 揭晓答案



理解了interface的构成，这道题就不难了，下面是答案和分析：
```go
package main

import "fmt"

type Human interface {
    Say() string
}

type Man struct {
}

func (m *Man) Say() string {
    return "man"
}

func IsNil(h interface{}) bool {
    return h == nil
}

func main() {
    var a interface{}
    var b *Man
    var c *Man
    var d Human
    var e interface{}
    a = b
    e = a
    fmt.Println(a == nil) 
    // (1) false
    // a是eface类型，_type指向的是*Man类型，
    // data指向的是nil，所以此题为false
    
    fmt.Println(e == nil) 
    // (2) false
    // 同理，e为eface类型，_type也是指向的*Man类型
    
    fmt.Println(a == c)
    // (3) true
    // a的_type是*Man类型，data是nil
    // c的data也是nil
    
    fmt.Println(a == d)   
    // (4) false
    // a为eface类型，d为iface类型，而且d的itab指向的是nil，data也是nil
    // 因为d没有具体到哪种数据类型
    
    fmt.Println(c == d)   
    // (5) false
    // c和d其实是两种不同的数据类型
    
    fmt.Println(e == b)
    // (6) true
    // 分析见(4)
    
    fmt.Println(IsNil(c)) 
    // (7) false
    // c是*Man类型，以参数的形式传入IsNil方法
    // 虽然c指向的是nil，但是参数i的_type指向的是*Man，所以i不为nil
    
    fmt.Println(IsNil(d)) 
    // (8) true
    // d没有指定具体的类型，所以d的itab指向的是nil，data也是nil
}
```

### 参考文献：

>1. 《Go语言interface底层实现》https://i6448038.github.io/2018/10/01/Golang-interface/

>2. 《Go Data Structures: Interfaces》https://research.swtch.com/interfaces

>3. 《Go源码》https://golang.org/pkg/builtin/#pkg-variables



感谢阅读，欢迎大家指正，留言交流~

