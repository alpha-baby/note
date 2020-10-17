# mosn 变量机制

什么是变量机制可以参考这篇文章：[MOSN 源码解析 - 变量机制](https://mosn.io/blog/code/mosn-variable/)

简单一句话理解就是：通过程序缓存，获取预定义好的变量值。(如果你仔细研究透mosn提供的变量机制，再回来看这句话估计才能理解)

# go内置的context包

mosn的变量机制需要依赖go内置的context包来实现，了解清楚context包的原理可以对理解变量机制有很好的帮助。

go内置的`context/context.go: valueCtx`:

```golang
// A valueCtx carries a key-value pair. It implements Value for that key and
// delegates all other calls to the embedded Context.
type valueCtx struct {
    Context
    key, val interface{}
}
```

# mosn 自实现的context

类似go内置的`valueCtx`，mosn也自己实现了一个`valueCtx`，具体结构在：`pkg/context/context.go`。

```golang
type valueCtx struct {
    context.Context

    builtin [types.ContextKeyEnd]interface{}
}
```

获取值：

```golang
func (c *valueCtx) Value(key interface{}) interface{} {
    if contextKey, ok := key.(types.ContextKey); ok { // 定义好的int常量类型
        return c.builtin[contextKey]
    }
    return c.Context.Value(key)
}
```

# 分析单元测试

**和上文参考的文章一样，我们通过单元测试来分析mosn的变量机制的基本原理**

```golang
// DefaultAccessLogFormat provides a pre-defined format
const DefaultAccessLogFormat = "%start_time% %request_received_duration% %response_received_duration% %bytes_sent%" + " " +
    "%bytes_received% %protocol% %response_code% %duration% %response_flag% %response_code% %upstream_local_address%" + " " +
    "%downstream_local_address% %downstream_remote_address% %upstream_host%"

func TestAccessLog(t *testing.T) {
    registerTestVarDefs() // 注册预定义变量

    format := types.DefaultAccessLogFormat
    logName := "/tmp/mosn_bench/benchmark_access.log"
    os.Remove(logName)
    accessLog, err := NewAccessLog(logName, format) // 新建accesslog，需要先提前了解mosn log 模块
    // ...
    ctx := prepareLocalIpv6Ctx() //  构造context上下文信息
    accessLog.Log(ctx, nil, nil, nil)
    // ...
}
```

## 分析单元测试中的valueCtx

具体的构造上下文信息如下：

```golang
func prepareLocalIpv6Ctx() context.Context {
    ctx := context.Background()
    ctx = variable.NewVariableContext(ctx) // 新建变量机制上下文

    reqHeaders := map[string]string{
        "service": "test",
    }
    ctx = context.WithValue(ctx, requestHeaderMapKey, reqHeaders)

    respHeaders := map[string]string{
        "Server": "MOSN",
    }
    ctx = context.WithValue(ctx, responseHeaderMapKey, respHeaders)

    requestInfo := newRequestInfo()
    // ...
    ctx = context.WithValue(ctx, requestInfoKey, requestInfo)

    return ctx
}
```

`NewVariableContext`方法，

```golang
func NewVariableContext(ctx context.Context) context.Context {
    // TODO: sync.Pool reuse
    values := make([]IndexedValue, len(indexedVariables)) // TODO: pre-alloc buffer for runtime variable

    return mosnctx.WithValue(ctx, types.ContextKeyVariables, values)
}
```

`mosnctx.WithValue(ctx, types.ContextKeyVariables, values)`方法

```golang
func WithValue(parent context.Context, key types.ContextKey, value interface{}) context.Context {
    if mosnCtx, ok := parent.(*valueCtx); ok {
        mosnCtx.builtin[key] = value
        return mosnCtx
    }

    // create new valueCtx
    mosnCtx := &valueCtx{Context: parent}
    mosnCtx.builtin[key] = value
    return mosnCtx
}
```

我们可以在单元测试中用IDE的debug功能查看新建`valueCtx`后的结果:

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gij9w08jwtj30es0cz75r.jpg)

然后执行完`prepareLocalIpv6Ctx()`函数后，我们可以分析`ctx`的结果：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gij9xzu4abj30gn06u75i.jpg)

从图中可以分析，`ctx` 上下文一层套一层，就类似链表一样。

## 分析单元测试中的变量注册

注册函数如下：

```golang
var (
    builtinVariables = []variable.Variable{
        variable.NewBasicVariable(varStartTime, nil, startTimeGetter, nil, 0),
        variable.NewBasicVariable(varRequestReceivedDuration, nil, receivedDurationGetter, nil, 0),
        ...
    }

    prefixVariables = []variable.Variable{
        variable.NewBasicVariable(reqHeaderPrefix, nil, requestHeaderMapGetter, nil, 0),
        variable.NewBasicVariable(respHeaderPrefix, nil, responseHeaderMapGetter, nil, 0),
    }
)

func registerTestVarDefs() {
    // register built-in variables
    for idx := range builtinVariables { // 注册进去的值是： type BasicVariable struct, 这个结构体是实现了 type Variable interface 
        variable.RegisterVariable(builtinVariables[idx])
    }

    // register prefix variables, like header_xxx/arg_xxx/cookie_xxx
    for idx := range prefixVariables {
        variable.RegisterPrefixVariable(prefixVariables[idx].Name(), prefixVariables[idx])
    }
}
```

注册变量的原理就是把一个结构体存放到：`map[string]Variable` 的一个map中，上文中BasicVariable

从`BasicVariable`的具体结构分析：

```golang
// implement variable.Variable
type BasicVariable struct {
    getter GetterFunc
    setter SetterFunc

    name  string
    data  interface{}
    flags uint32
}
```

![](https://mosn.io/blog/code/mosn-variable/variable.png)

我们在对应原理图，分析`BasicVariable`的结构，可知道：我们用一个特定的字符串，从上文中的map中取出`Varibale`对象，然后通过`GetterFunc`来生成预定义好的值。

## mosn 从变量缓存中获取数据

获取数据的函数在：`pkg/log/accesslog.go: func (l *accesslog) Log(ctx context.Context, ...)`

```golang
func (l *accesslog) Log(ctx context.Context, reqHeaders api.HeaderMap, respHeaders api.HeaderMap, requestInfo api.RequestInfo) {
    // return directly
    if l.logger.Disable() {
        return
    }

    buf := buffer.GetIoBuffer(AccessLogLen)
    for idx := range l.entries {
        l.entries[idx].log(ctx, buf) // 把没给entry写入到buffer中
    }
    buf.WriteString("\n")
    l.logger.Print(buf, true)
}
```

写入到buffer的具体逻辑

```golang
func (le *logEntry) log(ctx context.Context, buf buffer.IoBuffer) {
    if le.text != "" {
        buf.WriteString(le.text)
    } else {
        value, err := variable.GetVariableValue(ctx, le.variable.Name()) // 从缓存中取得每个entry的预定于值
        if err != nil {
            buf.WriteString(variable.ValueNotFound)
        } else {
            buf.WriteString(value)
        }
    }
}
```

取值的主要逻辑为：

```golang
func GetVariableValue(ctx context.Context, name string) (string, error) {
    // 1. find built-in variables
    if variable, ok := variables[name]; ok {
        // 1.1 check indexed value
        // ...
        // 1.2 use variable.Getter() to get value
        getter := variable.Getter() // 这了的getter 就是我们前文分析的在注册预定义变量注册进去的 BasicVariable.GetterFunc
        if getter == nil {
            return "", errors.New(errGetterNotFound + name)
        }
        return getter(ctx, nil, variable.Data())
    }
}
```

这里我们可以以预定义注册进去的`start_time`变量为例，分析是怎么获取到这个预定于变量的，`start_time`的预定义Getter为：

```golang
// StartTimeGetter
// get request's arriving time
func startTimeGetter(ctx context.Context, value *variable.IndexedValue, data interface{}) (string, error) {
    info := ctx.Value(requestInfoKey).(api.RequestInfo)
    return info.StartTime().Format("2006/01/02 15:04:05.000"), nil
}
```

我们可以用IDE自带的debug功能走到代码中的这里，找到`start_time`变量

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gijbf5txjoj30qr0ivmzv.jpg)

通过debug的`step into`，然后一层层进入，就可以找打`start_time`的`Getter`函数：

![](https://tva1.sinaimg.cn/large/007S8ZIlly1gijbrf0co4j30fg02vmxf.jpg)


## IndexedVariable

mosn还提供了一个`IndexedVariable`结构体：

```golang
// variable.Variable
// variable.VariableIndexer
type IndexedVariable struct {
    BasicVariable // 包装了 BasicVariable

    index uint32
}
```

`IndexedVariable`的目的是为了让注册进入缓存中的变量有序，序列的存储是用一个切片来存储。

```golang
indexedVariables = make([]Variable, 0, 32)       // indexed variables
```