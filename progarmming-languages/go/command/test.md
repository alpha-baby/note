# goland 配置测试

goland 的基本配置有：

1. Test framework: 测试框架，我们可以选三种：**go test**，**go bench**，**go check**
2. Test kind: test类型，我们也可以有三个可选：**Directory**，**Package**，**File**
    - 如果想测试整个项目如果用goland，可以选**Directory**，则会递归的测试该文件夹下的所有包，如果用命令可以使用：`go test ./...`
3. output directory: 编译好的二进制程序输出的目录
4. go tool 参数: 比如我们要做覆盖率测试，我们可以在这个选项中填上`-cover`参数
5. Program arguments: 运行二进制程序的时候带的命令行参数


# Race Detector(竞态分析）测试

并发设计使得程序可以更好更有效的利用现代处理器的多核心。但并发设计很容易引入竞态，导致严重bug。Go程序中竞态就是当多个goroutine并发 访问某共享数据且未使用同步机制时，且至少一个goroutine进行了写操作。不过go工具自带race分析功能。

*注意：*-race通过做运行时分析做竞态分析，虽然不存在误报，但却存在实际有竞态，但工具没发现的情况。

# benchmark

## 参数说明：

**英文**

```
 -test.bench regexp
        run only benchmarks matching regexp
  -test.benchmem
        print memory allocations for benchmarks
  -test.benchtime d
        run each benchmark for duration d (default 1s)
  -test.blockprofile file
        write a goroutine blocking profile to file
  -test.blockprofilerate rate
        set blocking profile rate (see runtime.SetBlockProfileRate) (default 1)
  -test.count n
        run tests and benchmarks n times (default 1)
  -test.coverprofile file
        write a coverage profile to file
  -test.cpu list
        comma-separated list of cpu counts to run each test with
  -test.cpuprofile file
        write a cpu profile to file
  -test.failfast
        do not start new tests after the first test failure
  -test.list regexp
        list tests, examples, and benchmarks matching regexp then exit
  -test.memprofile file
        write an allocation profile to file
  -test.memprofilerate rate
        set memory allocation profiling rate (see runtime.MemProfileRate)
  -test.mutexprofile string
        write a mutex contention profile to the named file after execution
  -test.mutexprofilefraction int
        if >= 0, calls runtime.SetMutexProfileFraction() (default 1)
  -test.outputdir dir
        write profiles to dir
  -test.parallel n
        run at most n tests in parallel (default 12)
  -test.run regexp
        run only tests and examples matching regexp
  -test.short
        run smaller test suite to save time
  -test.testlogfile file
        write test action log to file (for use only by cmd/go)
  -test.timeout d
        panic test binary after duration d (default 0, timeout disabled)
  -test.trace file
        write an execution trace to file
  -test.v
        verbose: print additional output
```

**中文，常用**

* `-run regexp`: 表示要运行哪一个test函数，此选项支持正则和`|`
* `-bench regexp`: 表示要运行哪一个benchmark函数，此选项支持正则和`|`
* `-benchmem`: 参数以显示内存分配情况，
* `-cover`: 开启测试覆盖率；
* `-benchtime`: 表示每个测试函数运行的时间，例如：2s
* `-cpuprofile=prof.cpu`: 表示输出CPU的profile信息到文件：**prof.cpu**
* `-parallel n`: 表示最多多少个tests并行执行
* `-cpu list`: 表示多少个cpu去执行每个test
* `-race`: 做竞态测试，可参考上文：**Race Detector(竞态分析）测试**


## 控制计时器

有些测试需要一定的启动和初始化时间，如果从 Benchmark() 函数开始计时会很大程度上影响测试结果的精准性。testing.B 提供了一系列的方法可以方便地控制计时器，从而让计时器只在需要的区间进行测试。我们通过下面的代码来了解计时器的控制。

```golang
func Benchmark_Add_TimerControl(b *testing.B) {
    // 重置计时器
    b.ResetTimer()
    // 停止计时器
    b.StopTimer()
    // 开始计时器
    b.StartTimer()
    var n int
    for i := 0; i < b.N; i++ {
        n++
    }
}
```

# CPU Profiling

## go benchmark

要做CPU Profilling，我们需要benchmark数据，Go test提供benchmark test功能，我们只要写对应的Benchmark测试方法即可。

可以用如下命令来做benchmark：

```bash
go test -v -run=^$ -bench=. ./...
```

其中`./...`的意思是递归的把当前目录下的所有包都做benchmark。

## cpu profiling

```bash
go test -v -run=^$ -bench=^BenchmarkHi$ -benchtime=2s -cpuprofile=prof.cpu
```

其中参数：

* `-bench=^BenchmarkHi$`: 表示要运行哪一个benchmark函数，此选项支持正则和`|`
* `-benchtime=2s`: 表示每个测试函数运行的时间
* `-cpuprofile=prof.cpu`: 表示输出CPU的profile信息到文件：**prof.cpu**

# Mem Profiling

生成测试数据：

```bash
go test -v -run=^$ -bench=^BenchmarkHi$ -benchtime=2s -memprofile=prof.mem
```

使用pprof工具分析mem：

```
go tool pprof –alloc_space package.test prof.mem
```

# Benchcmp

golang.org/x/tools中有一个工具：benchcmp，可以给出两次bench的结果对比。

github.com/golang/tools是golang.org/x/tools的一个镜像。安装benchcmp步骤：

```
1、git clone -u https://github.com/golang/tools.git
2、mkdir -p $GOPATH/src/golang.org/x
3、mv tools $GOPATH/src/golang.org/x
4、go install golang.org/x/tools/cmd/benchcmp
```


我们分别在step2、step3和step4下执行如下命令：

```
step2$ go test -bench=. -memprofile=prof.mem | tee mem.2
step3$ go test -bench=. -memprofile=prof.mem | tee mem.3
step4$ go test -bench=. -memprofile=prof.mem | tee mem.4
```

对比结果：

```bash
$ benchcmp step3/mem.3 step4/mem.4
$ benchcmp step2/mem.2 step4/mem.4
```

# 竞争优化

```bash
go test -bench=Parallel -blockprofile=prof.block
```

