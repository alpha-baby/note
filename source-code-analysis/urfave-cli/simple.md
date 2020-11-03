# cli

[cli](https://github.com/urfave/cli)是一款简单快速的用于构建GO命令行程序的工具包

目前此工具包已经有了V2版本，但是此文章只会分析V1版本，具体的版本号为：v1.22.5

# demo

首先给出一个用`cli`包编写的demo程序：

```go
package main

import (
    "github.com/urfave/cli"
    "os"
    "strconv"
    "time"
)

var (
    cmdStart = cli.Command{
        Name:  "start",
        Usage: "start demo app",
        Flags: []cli.Flag{
            cli.StringFlag{
                Name:   "config, c",
                Usage:  "Load configuration from `FILE`",
                EnvVar: "CONFIG",
                Value:  "configs/config.json",
            }, cli.StringSliceFlag{
                Name:   "replicas, r",
                Usage:  "replicas number",
                EnvVar: "REPLICAS",
            }, cli.StringFlag{
                Name:   "log-level, l",
                Usage:  "demo log level, trace|debug|info|warning|error|critical|off",
                EnvVar: "LOG_LEVEL",
            },
        },
        Action: func(c *cli.Context) error {
            configPath := c.String("config")
            replicas := c.Uint("replicas")
            flagLogLevel := c.String("log-level")

            fmt.Printf("config: %s \n", configPath)
            fmt.Printf("replicas: %d \n", replicas)
            fmt.Printf("flagLogLevel: %s \n", flagLogLevel)

            return nil
        },
    }
)

// Version demo version
var Version = "0.1.0"

func main() {
    app := newDemoApp(&cmdStart)

    // ignore error
    _ = app.Run(os.Args)
}

func newDemoApp(startCmd *cli.Command) *cli.App {
    app := cli.NewApp()
    app.Name = "demo"
    app.Version = Version
    app.Compiled = time.Now()
    app.Copyright = "(c) " + strconv.Itoa(time.Now().Year()) + " demo Financial"
    app.Usage = "DEMO is github.com/urfave/cli demo to learn cli."
    app.Flags = cmdStart.Flags

    //commands
    app.Commands = []cli.Command{
        cmdStart,
    }

    //action
    app.Action = func(c *cli.Context) error {
        if c.NumFlags() == 0 {
            return cli.ShowAppHelp(c)
        }
        return startCmd.Action.(func(c *cli.Context) error)(c)
    }

    return app
}
```

# Goland tool

这里我会使用Goland 工具来调试代码，运行配置如下图：

![](https://tva1.sinaimg.cn/large/0081Kckwly1gkc17d24jgj30mp0cfwfm.jpg)

然后点击运行，可以得到如下输出：

```txt
config: configs/config.json
replicas: 12
flagLogLevel:  
```

# debug 源码浅析

然后我们把断点定位到此处：

![](https://tva1.sinaimg.cn/large/0081Kckwly1gkc1aiag36j30et07d0tk.jpg)

然后点击`debug`运行，然后程序就会运行到我们打的断点的地方，然后一直点击`step into`就可以一直进入到此方法中：

```go
func lookupString(name string, set *flag.FlagSet) string {
    f := set.Lookup(name) // 从此处获取的参数值，继续从此处 step into
    if f != nil {
        parsed, err := f.Value.String(), error(nil)
        if err != nil {
            return ""
        }
        return parsed
    }
    return ""
}
```

继续`step into`我们可以找到如下函数：

```go
// Lookup returns the Flag structure of the named flag, returning nil if none exists.
func (f *FlagSet) Lookup(name string) *Flag {
    return f.formal[name]
}
```

`FlagSet`结构体是在go内置包中的：`flag`包中，具体结构如下：

```go
type FlagSet struct {
    Usage func()
    name          string
    parsed        bool
    actual        map[string]*Flag
    formal        map[string]*Flag
    args          []string // arguments after flags
    errorHandling ErrorHandling
    output        io.Writer // nil means stderr; use out() accessor
}
```

`Flag`结构构体的具体结构如下：

```go
// A Flag represents the state of a flag.
type Flag struct {
    Name     string // name as it appears on command line
    Usage    string // help message
    Value    Value  // value as set
    DefValue string // default value (as text); for usage message
}
```

此时我们可以在Goland中查看变量`f.formal`的值：

![](https://tva1.sinaimg.cn/large/0081Kckwly1gkc1v1m96uj30ls0lc41t.jpg)

这里我们可以看到在前文运行后输出的结果：`12`的来源，值`configs/config.json`是我们设定的默认值。

我们可以判断的是最终命令行参数的值保存在`FlagSet.formal`中，但是这个值是怎样设置进去的呢？

从我们demo程序的主函数中可以知道我们在运行的时候，我们传入了命令行参数：

```go
func main() {
    app := newDemoApp(&cmdStart)

    // ignore error
    _ = app.Run(os.Args)  // 这里传入了命令行参数 os.Args
}
```

点击函数的调用栈，可以知道在执行`app.Run(os.Args)`后出入的值：

![](https://tva1.sinaimg.cn/large/0081Kckwly1gkc29i71ocj30vh0adwhb.jpg)

我们只需要分析在此函数中哪个地方去解析了这个变量，基本可以知道这个框架在哪个地方去设置了命令行参数的值。

观察变量被引用的地方，可以知道只有两个变量：

```go
func (a *App) Run(arguments []string) (err error) {
    a.Setup()
    shellComplete, arguments := checkShellCompleteFlag(a, arguments) // here 1

    set, err := a.newFlagSet()
    if err != nil {
        return err
    }

    err = parseIter(set, a, arguments[1:], shellComplete) // here 2
    // .....
}
```

使用Goland分别点进每个函数看一下，经过简单分析我们可以知道，大概率应该是在`here 2`里面解析的，然后我们终止程序，再在`here 2`处打上断点。

然后我们就是可以进入到此函数处：

```go
func parseIter(set *flag.FlagSet, ip iterativeParser, args []string, shellComplete bool) error {
    for {
        err := set.Parse(args) // step into
        // .....
    }
}
```

这里我们可以注意到此函数传入了一个：`set *flag.FlagSet`,并且参数是指针。

```go
func (f *FlagSet) Parse(arguments []string) error {
    f.parsed = true
    f.args = arguments // 重点，但是在这里，我们并没有传入更多的参数，在此打上断点
    for {
        seen, err := f.parseOne() // step into 
        if seen {
            continue
        }
        if err == nil {
            break
        }
        switch f.errorHandling {
        case ContinueOnError:
            return err
        case ExitOnError:
            os.Exit(2)
        case PanicOnError:
            panic(err)
        }
    }
    return nil
}
```

重新修改启动参数，重新启动，具体的参数配置如下：

![](https://tva1.sinaimg.cn/large/0081Kckwly1gkc2vuewtnj30mt0djq4c.jpg)

重新执行后，再次运行到上面给出的函数处，然后我们进入函数：`f.parseOne()`中：

```go
func (f *FlagSet) parseOne() (bool, error) {
    if len(f.args) == 0 {
        return false, nil
    }
    s := f.args[0]
    if len(s) < 2 || s[0] != '-' {
        return false, nil // 运行到这里就自然退出了，就很奇怪，一度怀疑是不是我分析错了
    }
    // ....
}
```

然后我们执行`Resume program`，然后可以重新进入函数：`func (f *FlagSet) Parse(arguments []string) error`

```go
func (a *App) Run(arguments []string) (err error) {
    // .....
    args := context.Args()
    if args.Present() {
        name := args.First()
        c := a.Command(name)
        if c != nil {
            return c.Run(context) // 可以发现是这里执行到了 函数 `func (f *FlagSet) Parse(arguments []string) error`
        }
    }
    // ....
}
```

最终可以发现，在这个函数中解析了命令行的参数：

```go
// failf prints to standard error a formatted error and usage message and
// returns the error.
func (f *FlagSet) failf(format string, a ...interface{}) error {
    // ...
}
```

# 总结

分析到这里，我们就可以结束了，通过这次分析，我们可以知道，cli工具包只是对官方包：`flag`的一个二次封装，使其更加强大。