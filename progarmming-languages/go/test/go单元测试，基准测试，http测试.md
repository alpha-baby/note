# Go 单元测试，基准测试，http 测试
====================

原文链接：https://deepzz.com/post/study-golang-test.html

**预览目录**

*   [Test 测试](#toc_0)
*   [Benchmark 测试](#toc_1)
*   [Example 测试](#toc_2)
*   [子测试](#toc_3)
*   [Main 测试](#toc_4)
*   [HTTP 测试](#toc_5)

对我们程序员来说，如何提高代码质量一定是我们的重中之重。不仅需要你能够写得一手的业务代码，还需要做的是如何保证你的代码质量。测试用例便是一个非常好的用来提高我们代码质量的工具。

通过测试，我们能够及时的发现我们程序的设计逻辑错误，并能够给接手项目的其它程序员同学理解函数有帮助。

本篇文章主要介绍 Go 语言中的 testing 包。它要求我们以 `*_test.go` 新建文件，并在文件中以 `TestXxx` 命名函数。然后再通过 `go test [flags] [packages]` 执行函数。

    $ ls
    db.go
    db_test.go
    
    $ cat db_test.go
    package db
    
    import "testing"
    
    func TestGetUser(t *testing.T) {
        user, err := GetUser("test@example.com")
        if err != nil {
            t.Fatal(err)
        }
        t.Log(user)
    }
    

它也为我们提供了三种类型的函数：测试函数 T、基准测试函数 B、实例函数 Example。

### Test 测试

函数测试，其基本签名是：

    func TestName(t *testing.T){
        // ...
    }
    

测试函数的名字必须以 `Test` 开头，可选的后缀名必须不以小写字母开头，一般跟我们测试的函数名。

类型 `testing.T` 有以下方法：

    // 打印日志。对于测试，会在失败或指定 -test.v 标志时打印。对与基准测试，总是打印，避免因未指定 -test.v 带来的测试不准确
    func (c *T) Log(args ...interface{})
    func (c *T) Logf(format string, args ...interface{})
    
    
    // 标记函数失败，继续执行该函数
    func (c *T) Fail()
    // 标记函数失败，调用 runtime.Goexit 退出该函数。但继续执行其它函数或基准测试。
    func (c *T) FailNow()
    // 返回函数是否失败
    func (c *T) Failed() bool
    
    
    // 等同于 t.Log + t.Fail
    func (c *T) Error(args ...interface{})
    // 等同于 t.Logf + t.Fail
    func (c *T) Errorf(format string, args ...interface{})
    
    
    // 等同于 t.Log + t.FailNow
    func (c *T) Fatal(args ...interface{})
    // 等同于 t.Logf + t.FailNow
    func (c *T) Fatalf(format string, args ...interface{})
    
    
    // 将调用函数标记标记为测试助手函数。
    func (c *T) Helper()
    
    // 返回正在运行的测试或基准测试的名称
    func (c *T) Name() string
    
    // 用于表示当前测试只会与其他带有 Parallel 方法的测试并行进行测试。
    func (t *T) Parallel()
    
    // 执行名字为 name 的子测试 f，并报告 f 在执行过程中是否失败
    // Run 会阻塞到 f 的所有并行测试执行完毕。
    func (t *T) Run(name string, f func(t *T)) bool
    
    
    // 相当于 t.Log + t. SkipNow
    func (c *T) Skip(args ...interface{})
    // 将测试标记为跳过，并调用 runtime.Goexit 退出该测试。继续执行其它测试或基准测试
    func (c *T) SkipNow()
    // 相当于 t.Logf + t.SkipNow
    func (c *T) Skipf(format string, args ...interface{})
    // 报告该测试是否是忽略
    func (c *T) Skipped() bool
    

### Benchmark 测试

函数测试，其基本签名是：

    func BenchmarkName(b *testing.B){
        // ...
    }
    

测试函数的名字必须以 `Benchmark` 开头，可选的后缀名必须不以小写字母开头，一般跟我们测试的函数名。

B 类型有一个参数 N，它可以用来只是基准测试的迭代运行的次数。基准测试与测试，基准测试总是会输出日志。

    type B struct {
        N int
        // contains filtered or unexported fields
    }
    

基准测试较测试多了些函数：

    func (c *B) Log(args ...interface{})
    func (c *B) Logf(format string, args ...interface{})
    func (c *B) Fail()
    func (c *B) FailNow()
    func (c *B) Failed() bool
    func (c *B) Error(args ...interface{})
    func (c *B) Errorf(format string, args ...interface{})
    func (c *B) Fatal(args ...interface{})
    func (c *B) Fatalf(format string, args ...interface{})
    func (c *B) Helper()
    func (c *B) Name() string
    func (b *B) Run(name string, f func(b *B)) bool
    func (c *B) Skip(args ...interface{})
    func (c *B) SkipNow()
    func (c *B) Skipf(format string, args ...interface{})
    func (c *B) Skipped() bool
    
    
    // 打开当前基准测试的内存统计功能，与使用 -test.benchmem 设置类似，
    // 但 ReportAllocs 只影响那些调用了该函数的基准测试。
    func (b *B) ReportAllocs()
    
    // 对已经逝去的基准测试时间以及内存分配计数器进行清零。对于正在运行中的计时器，这个方法不会产生任何效果。
    func (b *B) ResetTimer()
    例：
    func BenchmarkBigLen(b *testing.B) {
        big := NewBig()
        b.ResetTimer()
        for i := 0; i < b.N; i++ {
            big.Len()
        }
    }
    
    // 以并行的方式执行给定的基准测试。RunParallel 会创建出多个 goroutine，并将 b.N 个迭代分配给这些 goroutine 执行，
    // 其中 goroutine 数量的默认值为 GOMAXPROCS。用户如果想要增加非CPU受限（non-CPU-bound）基准测试的并行性，
    // 那么可以在 RunParallel 之前调用 SetParallelism。RunParallel 通常会与 -cpu 标志一同使用。
    // body 函数将在每个 goroutine 中执行，这个函数需要设置所有 goroutine 本地的状态，
    // 并迭代直到 pb.Next 返回 false 值为止。因为 StartTimer、StopTimer 和 ResetTimer 这三个函数都带有全局作用，所以 body函数不应该调用这些函数；
    // 除此之外，body 函数也不应该调用 Run 函数。
    func (b *B) RunParallel(body func(*PB))
    例：
    func BenchmarkTemplateParallel(b *testing.B) {
        templ := template.Must(template.New("test").Parse("Hello, {{.}}!"))
        b.RunParallel(func(pb *testing.PB) {
            var buf bytes.Buffer
            for pb.Next() {
                buf.Reset()
                templ.Execute(&buf, "World")
            }
        })
    }
    
    
    // 记录在单个操作中处理的字节数量。 在调用了这个方法之后， 基准测试将会报告 ns/op 以及 MB/s
    func (b *B) SetBytes(n int64)
    
    // 将 RunParallel 使用的 goroutine 数量设置为 p*GOMAXPROCS，如果 p 小于 1，那么调用将不产生任何效果。
    // CPU受限（CPU-bound）的基准测试通常不需要调用这个方法。
    func (b *B) SetParallelism(p int)
    
    // 开始对测试进行计时。
    // 这个函数在基准测试开始时会自动被调用，它也可以在调用 StopTimer 之后恢复进行计时。
    func (b *B) StartTimer()
    
    // 停止对测试进行计时。
    func (b *B) StopTimer()
    

### Example 测试

示例函数可以帮助我们写一个示例，并与输出相比较：

    func ExampleHello() {
        fmt.Println("hello")
        // Output: hello
    }
    
    func ExampleSalutations() {
        fmt.Println("hello, and")
        fmt.Println("goodbye")
        // Output:
        // hello, and
        // goodbye
    }
    
    // 无序输出 Unordered output
    func ExamplePerm() {
        for _, value := range Perm(4) {
            fmt.Println(value)
        }
        // Unordered output: 4
        // 2
        // 1
        // 3
        // 0
    }
    

关于示例函数我们需要知道：

*   函数的签名需要以 `Example` 开头
*   输出的对比有有序（Output）和无序（Unordered output）两种
*   如果函数没有输出注释，将不会被执行

官方给我们的命名的规则是：

    // 一个包的 example
    func Example() { ... }
    // 一个函数 F 的 example
    func ExampleF() { ... }
    // 一个类型 T 的 example
    func ExampleT() { ... }
    // 一个类型 T 的方法 M 的 example
    func ExampleT_M() { ... }
    
    // 如果以上四种类型需要提供多个示例，可以通过添加后缀的方式
    // 后缀必须小写
    func Example_suffix() { ... }
    func ExampleF_suffix() { ... }
    func ExampleT_suffix() { ... }
    func ExampleT_M_suffix() { ... }
    

### 子测试

上面我们也说到了 Test 和 Benchmark 的 `Run` 方法，它用来执行子测试。

    func TestFoo(t *testing.T) {
        // <setup code>
        t.Run("A=1", func(t *testing.T) { ... })
        t.Run("A=2", func(t *testing.T) { ... })
        t.Run("B=1", func(t *testing.T) { ... })
        // <tear-down code>
    }
    

每个子测试可以用一个唯一的名字表示：顶级测试的名称和传递给 Run 的名称序的组合，用 `/` 分隔。

    go test -run ''      # 运行所有测试
    go test -run Foo     # 匹配 Foo 相关的顶级测试，如 TestFooBar
    go test -run Foo/A=  # 匹配 Foo 相关的顶级测试, 并匹配子测试 A=
    go test -run /A=1    # 匹配所有顶级测试, 并匹配它们的子测试 A=1
    

子测试也可以用来控制并行性。父级测试只有在完成所有子测试后才能完成。在这个例子中，所有的测试都是相互平行的，并且只与对方一起运行，而不管可能定义的其它顶级测试：

    func TestGroupedParallel(t *testing.T) {
        for _, tc := range tests {
            tc := tc // capture range variable
            t.Run(tc.Name, func(t *testing.T) {
                t.Parallel()
                ...
            })
        }
    }
    

运行直到并行子测试完成才会返回，这提供了一种在一组并行测试后进行清理的方法：

    func TestTeardownParallel(t *testing.T) {
        // This Run will not return until the parallel tests finish.
        t.Run("group", func(t *testing.T) {
            t.Run("Test1", parallelTest1)
            t.Run("Test2", parallelTest2)
            t.Run("Test3", parallelTest3)
        })
        // <tear-down code>
    }
    

### Main 测试

有时候我们也需要从主函数开始进行测试：

    func TestMain(m *testing.M)
    
    例：
    func TestMain(m *testing.M) {
        // call flag.Parse() here if TestMain uses flags
        os.Exit(m.Run())
    }
    

### HTTP 测试

Go 语言目前的 web 开发是比较多的，那么在我们对功能函数有了测试之后，HTTP 的测试又该怎样做呢？

Go 的标准库为我们提供了一个 [httptest](https://golang.org/pkg/net/http/httptest/) 的库，通过它就能够轻松的完成 HTTP 的测试。

1、测试 Handle 函数

    package main
    
    import (
        "fmt"
        "io"
        "io/ioutil"
        "net/http"
        "net/http/httptest"
    )
    
    var HandleHelloWorld = func(w http.ResponseWriter, r *http.Request) {
        io.WriteString(w, "<html><body>Hello World!</body></html>")
    }
    
    func main() {
        req := httptest.NewRequest("GET", "http://example.com/foo", nil)
        w := httptest.NewRecorder()
        HandleHelloWorld(w, req)
    
        resp := w.Result()
        body, _ := ioutil.ReadAll(resp.Body)
    
        fmt.Println(resp.StatusCode)
        fmt.Println(resp.Header.Get("Content-Type"))
        fmt.Println(string(body))
    }
    

2、TLS 服务器？

    package main
    
    import (
        "fmt"
        "io/ioutil"
        "log"
        "net/http"
        "net/http/httptest"
    )
    
    func main() {
        ts := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintln(w, "Hello, client")
        }))
        defer ts.Close()
    
        client := ts.Client()
        res, err := client.Get(ts.URL)
        if err != nil {
            log.Fatal(err)
        }
    
        greeting, err := ioutil.ReadAll(res.Body)
        res.Body.Close()
        if err != nil {
            log.Fatal(err)
        }
    
        fmt.Printf("%s", greeting)
    }
    

3、常用的 HTTP 框架又如何测试？

    // Package main provides ...
    package main
    
    import (
        "fmt"
        "net/http"
        "net/http/httptest"
    
        "github.com/gin-gonic/gin"
    )
    
    func main() {
        engine := gin.Default()
        engine.GET("/hello", func(c *gin.Context) { c.String(http.StatusOK, "Hello") })
        engine.GET("/world", func(c *gin.Context) { c.String(http.StatusOK, "world") })
    
        req := httptest.NewRequest(http.MethodGet, "/hello", nil)
        w := httptest.NewRecorder()
    
        engine.ServeHTTP(w, req)
    
        fmt.Println(w.Body.String())
    }
    

本文链接：[https://deepzz.com/post/study-golang-test.html](//deepzz.com/post/study-golang-test.html "Permalink to Go 单元测试，基准测试，http 测试")，[参与评论 »](//deepzz.com/post/study-golang-test.html#comments)

--EOF--

发表于 2018-05-09 23:31:00，并被添加「[go](/search.html?q=tag:go)、[test](/search.html?q=tag:test)」标签。

本站使用「[署名 4.0 国际](//creativecommons.org/licenses/by/4.0/)」创作共享协议，转载请注明作者及原网址。[更多说明 »](//deepzz.com/post/about.html#toc_1)

提醒：本文最后更新于 440 天前，文中所描述的信息可能已发生改变，请谨慎使用。

### 专题「Go 踩坑系列」的其它文章 [»](/series.html#toc-4 "更多")

*   [Go 测试，go test 工具的具体指令 flag](/post/the-command-flag-of-go-test.html) (May 20, 2018)
*   [Go 关键字 defer 的一些坑](/post/how-to-use-defer-in-golang.html) (Aug 27, 2017)
*   [浅谈 Golang sync 包的相关使用方法](/post/golang-sync-package-usage.html) (Aug 19, 2017)
*   [Golang 博主走过的有关 error 的一些坑](/post/why-nil-error-not-equal-nil.html) (May 14, 2017)
*   [Glide命令，如何使用glide，glide.lock](/post/glide-package-management-command.html) (Feb 09, 2017)
*   [Golang包管理工具Glide，你值得拥有](/post/glide-package-management-introduce.html) (Feb 07, 2017)