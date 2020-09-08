# mosn 日志模块

> 参考
> https://mosn.io/blog/code/mosn-log/


# mosn 中的两种日志

1. ErrorLogger
2. accessLog

## ErrorLogger

从日志文件中来看，分别有这样的层级结构：servers -> listeners

```json
{
  "servers": [
    {
      "default_log_path": "stdout",
      "default_log_level": "DEBUG",
      "listeners": [
        {
          ....
      ],
      "routers":[
          ....
      ]
    }
  ]
}
```

以上配置中的：`"default_log_path": "stdout","default_log_level": "DEBUG",`对应了`ErrorLogger`

## accessLog

从上文中的配置文件结构可以看出来，一个`server`可以对应多个`listener`，我们再看如下配置：

```json
{
    "servers": [
        {
            "mosn_server_name": "mosn_server_1",
            ......
            "listeners": [
                {
                    "name": "ingress_sofa",
                    ......
                    "log_path": "./logs/ingress.log",
                    "log_level": "DEBUG",
                    "access_logs": [
                        {
                            "log_path": "./logs/access_ingress.log",
                            "log_format": "%start_time% %request_received_duration% %response_received_duration% %bytes_sent% %bytes_received% %protocol% %response_code% %duration% %response_flag% %response_code% %upstream_local_address% %downstream_local_address% %downstream_remote_address% %upstream_host%"
                        }
                    ]
                }
            ]
        }
    ]
}
```

从以上配置文件可以看出来，每个listener 可以配置多个accesslog。

# ErrorLogger 详细详细分析

ErrorLogger的创建在文件：`pkg/log/logger_manager.go`中，进入文件后我们首先会发现有个`init()`函数，这个还是有什么作用就不同多提了，如果不知道可以去网上先学习一下。

```golang
func init() {
    // tip 管理 ErrorLogger，把所有的日志管理起来，这样便可以统一管理
    errorLoggerManagerInstance = &ErrorLoggerManager{
        mutex:    sync.Mutex{},
        managers: make(map[string]log.ErrorLogger),
    }
    // use console as start logger
    StartLogger, _ = GetOrCreateDefaultErrorLogger("", log.INFO) // tip 创建一个ErrorLogger
    // default as start before Init
    log.DefaultLogger = StartLogger
    DefaultLogger = log.DefaultLogger
    // default proxy logger for test, override after config parsed
    log.DefaultContextLogger, _ = CreateDefaultContextLogger("", log.INFO) // tip 创建一个ContextLogger
    Proxy = log.DefaultContextLogger
}
```

然后我们分析下函数：1. `GetOrCreateDefaultErrorLogger()` 2. `CreateDefaultContextLogger()`

```golang
// GetOrCreateDefaultErrorLogger used default create function
func GetOrCreateDefaultErrorLogger(p string, level log.Level) (log.ErrorLogger, error) {
	return errorLoggerManagerInstance.GetOrCreateErrorLogger(p, level, DefaultCreateErrorLoggerFunc)
}
```

```golang
func CreateDefaultContextLogger(output string, level log.Level) (log.ContextLogger, error) {
    lg, err := GetOrCreateDefaultErrorLogger(output, level)
    if err != nil {
        return nil, err
    }
    return &proxyLogger{
        ErrorLogger: lg,
    }, nil

}
```

我们可以发现，`ContextLogger` 就是把 `ErrorLogger` 用结构体：`proxyLogger`再次包装了一下。那么我们就着重分析：`ErrorLogger`。

分析可以得知，`ErrorLogger`的创建都统一到了:`ErrorLoggerManager`:

```golang
// Default Export Functions
func GetErrorLoggerManagerInstance() *ErrorLoggerManager {
	return errorLoggerManagerInstance
}

// GetOrCreateDefaultErrorLogger used default create function
func GetOrCreateDefaultErrorLogger(p string, level log.Level) (log.ErrorLogger, error) {
	return errorLoggerManagerInstance.GetOrCreateErrorLogger(p, level, DefaultCreateErrorLoggerFunc)
}

// GetOrCreateErrorLogger returns a ErrorLogger based on the output(p).
// If Logger not exists, and create function is not nil, creates a new logger
func (mng *ErrorLoggerManager) GetOrCreateErrorLogger(p string, level log.Level, f CreateErrorLoggerFunc) (log.ErrorLogger, error) {
	mng.mutex.Lock()
	defer mng.mutex.Unlock()
	if lg, ok := mng.managers[p]; ok { 
		return lg, nil
	}
	// only find exists
	if f == nil {
		return nil, ErrNoLoggerFound
	}
	lg, err := f(p, level) // f 是一个回电函数
	if err != nil {
		return nil, err
	}
	mng.managers[p] = lg // 把所有的logger 都统一存放到 map结构中
	return lg, nil
}
```

在上面中的回调函数是什么呢：

```golang
// tip 使用底层封装好的 logger roller 使用默认的 defaultRoller，默认每天轮转。
func CreateDefaultErrorLogger(output string, level log.Level) (log.ErrorLogger, error) {
    lg, err := log.GetOrCreateLogger(output, nil) // mosn 封装到底层的创建
    if err != nil {
        return nil, err
    }

    return &log.SimpleErrorLog{ // tip SimpleErrorLog 是对， mosn.io/pkg/log/logger.go:
        Logger:    lg,
        Formatter: log.DefaultFormatter,
        Level:     level,
    }, nil
}
```

再分析下，在log包外部，有什么地方会调用日志包创建`ErrorLog`，`log`包中提供了默认的初始化函数封装：

```golang
func InitDefaultLogger(output string, level log.Level) (err error) {
    defaultPath := output
    proxyPath := output

    if output != "stdout" {
        if strings.HasSuffix(output, "/") == false {
            output = output + "/"
        }
        defaultPath = output + types.MosnLog
        proxyPath = output + types.ProxyLog
    }
    DefaultLogger, err = GetOrCreateDefaultErrorLogger(defaultPath, level)
    if err != nil {
        return err
    }
    Proxy, err = CreateDefaultContextLogger(proxyPath, level)
    if err != nil {
        return err
    }
    // compatible for the mosn caller
    log.DefaultLogger = DefaultLogger // tip 修改底层封装的llogger 默认值 log.DefaultLogger 所在的位置为：mosn.io/pkg/log/errorlog.go
    log.DefaultContextLogger = Proxy // tip 同理
    return
}
```

只有一处调用了：`InitDefaultLogger`函数,`pkg/server/server.go`中：

```golang
func InitDefaultLogger(config *Config) {
    // ....
    if config.LogRoller != "" {
        err := log.InitGlobalRoller(config.LogRoller) // Roller 初始化，这个是干嘛的呢，后面再分析
        if err != nil {
            log.DefaultLogger.Fatalf("[server] [init] initialize default logger Roller failed : %v", err)
        }
    }

    err := mlog.InitDefaultLogger(logPath, logLevel) // 这里初始化了日志
    //....
}
```

继续分析，我们可以找到在初始化mosn对象的时候调用了日志初始化：

```golang
// pkg/mosn/starter.go
func NewMosn(c *v2.MOSNConfig) *Mosn {
    // ...
    for _, serverConfig := range c.Servers {
        //1. server config prepare
        //server config
        c := configmanager.ParseServerConfig(&serverConfig)

        // new server config
        sc := server.NewConfig(c)

        // init default log
        server.InitDefaultLogger(sc) // 初始化日志
        // ....
    }
    // ....
}
```

在：`pkg/mosn/starter.go`文件中，可以看到很多这种日志打印：

```golang
import "mosn.io/mosn/pkg/log"

log.StartLogger.Fatalf("[mosn] [NewMosn] graceful failed, exit")
```

在：`pkg/admin/server/apis.go`:

```golang
import "mosn.io/mosn/pkg/log"

log.DefaultLogger.Alertf("....")
```

在：`pkg/server/server.go`:

```golang
import "mosn.io/pkg/log"

log.DefaultLogger.Infof("[server] [reconfigure] [new server] Netpoll mode enabled.")
```

以三处，可以发现，在两个包中对应了同一个变量名的变量，其实有点不好区分，总觉得这种方式不太优雅，也有点不好区分。

上文中分析的函数：`func InitDefaultLogger(output string, level log.Level) (err error)`中，可以发现当，此函数被调用后，
`"mosn.io/mosn/pkg/log"`,`"mosn.io/pkg/log"` 这两个包中的：`DefaultLogger`是同一个值。

回到上文提到的函数：

```golang
// tip 使用底层封装好的 logger roller 使用默认的 defaultRoller，默认每天轮转。
func CreateDefaultErrorLogger(output string, level log.Level) (log.ErrorLogger, error) {
    lg, err := log.GetOrCreateLogger(output, nil) // mosn 封装到底层的创建
    if err != nil {
        return nil, err
    }

    return &log.SimpleErrorLog{ // tip SimpleErrorLog 是对， mosn.io/pkg/log/logger.go:
        Logger:    lg,
        Formatter: log.DefaultFormatter,
        Level:     level,
    }, nil
}
```

此结构体：`log.SimpleErrorLog`的结构具体如下：

```golang
// 实现了接口：mosn.io/pkg/log/types.go  type ErrorLogger interface
type SimpleErrorLog struct {
    *Logger // Logger 二次包装了Logger
    Formatter func(lv string, alert string, format string) string // 日志输出模板
    Level     Level // 输出日志级别
}
```

`Logger`的具体结构如下：

```golang
type Logger struct {
    // output is the log's output path
    // if output is empty(""), it is equals to stderr
    output string
    // writer writes the log, created by output
    writer io.Writer
    // roller rotates the log, if the output is a file path，如果日志输出到的是系统文件中，则会按照roller规则滚动日志，默认是一天滚动一次
    roller *Roller // tip 对应了前文提到的roller初始化
    // disable presents the logger state. if disable is true, the logger will write nothing
    // the default value is false
    disable bool
    // implementation elements
    create          time.Time
    reopenChan      chan struct{}
    closeChan       chan struct{}
    writeBufferChan chan buffer.IoBuffer
}
```

创建最核心的`Logger`结构体：

```golang
func GetOrCreateLogger(output string, roller *Roller) (*Logger, error) {
    if lg, ok := loggers.Load(output); ok { // loggers sync.Map, 使用map来存储所有的日志，不能重复
        return lg.(*Logger), nil
    }

    if roller == nil {
        roller = &defaultRoller // ，默认是一天滚动一次
    }

    lg := &Logger{
        output:          output,
        roller:          roller,
        writeBufferChan: make(chan buffer.IoBuffer, 500),
        reopenChan:      make(chan struct{}),
        closeChan:       make(chan struct{}),
        // writer and create will be setted in start()
    }
    err := lg.start() // 启动日志
    if err == nil { // only keeps start success logger
        loggers.Store(output, lg)
    }
    return lg, err
}
```

启动日志：

```golang
// 更具output 设置日志输出的地方
func (l *Logger) start() error {
	switch l.output {
	case "", "stderr", "/dev/stderr": // 
		l.writer = os.Stderr
	case "stdout", "/dev/stdout":
		l.writer = os.Stdout
	case "syslog": // 日子输出到系统日志中
		writer, err := gsyslog.NewLogger(gsyslog.LOG_ERR, "LOCAL0", "mosn") 
		if err != nil {
			return err
		}
		l.writer = writer
	default:
		if address := parseSyslogAddress(l.output); address != nil { // 通过网络把日志输出到远程
			writer, err := gsyslog.DialLogger(address.network, address.address, gsyslog.LOG_ERR, "LOCAL0", "mosn")
			if err != nil {
				return err
			}
			l.writer = writer
		} else { // write to file，输入日志到本地日志中
			if err := os.MkdirAll(filepath.Dir(l.output), 0755); err != nil {
				return err
			}
			file, err := os.OpenFile(l.output, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0644)
			if err != nil {
				return err
			}
			if l.roller.MaxTime == 0 {
				file.Close()
				l.roller.Filename = l.output
				l.writer = l.roller.GetLogWriter() // 返回一个三方的日志滚动器，gopkg.in/natefinch/lumberjack.v2，可以按照很多规则滚动日志文件
			} else {
				// time.Now() faster than reported timestamps from filesystem (https://github.com/golang/go/issues/33510)
				// init logger
				if l.create.IsZero() { // l.create 是一个重要的变量，后面会用此边浪来判断 根据时间的日志文件滚动
					stat, err := file.Stat()
					if err != nil {
						return err
					}
					l.create = stat.ModTime()
				} else {
					l.create = time.Now()
				}
				l.writer = file
			}
		}
	}
	// TODO: recover?
	go l.handler() // 启动处理器
	return nil
}
```

```golang
func (l *Logger) handler() {
	defer func() {
		if p := recover(); p != nil { // goroutine panic 后进行重启
			debug.PrintStack()
			// TODO: recover?
			go l.handler() // 重启
		}
	}()
	var buf buffer.IoBuffer
	for {
		select {
		case <-l.reopenChan: //  接受重启信号
			// reopen is used for roller
			err := l.reopen()
			if err == nil {
				return
			}
			fmt.Printf("%s reopen failed : %v\n", l.output, err)
		case <-l.closeChan: // 接受关闭信号
			// flush all buffers before close
			// make sure all logs are outputed
			// a closed logger can not write anymore
			for { // 关闭前保证缓存中的文件都清空
				select {
				case buf = <-l.writeBufferChan:
					buf.WriteTo(l)
					buffer.PutIoBuffer(buf)
				default:
					l.stop()
					return
				}
			}
        case buf = <-l.writeBufferChan: // 接受日志输出信号
            // 当收到第一次写数据的时候不是立刻写入数据到 log 对象，而是在等待 20 次读取信息，
            // 一起写入到对 log 象中，在大量写日志的时候不会导致调用太频繁。如频繁写入文件、
            // 频繁调用写日志接口，相反，这会增加内存分配，最好的其实是使用 writev，但是 
            // go runtime 的 io 库没有这个实现。可以采用 plugin 机制 来接管日志的打印，减少 io 卡顿对 go runtime 的调度影响
			for i := 0; i < 20; i++ { // 优化处理 
				select {
				case b := <-l.writeBufferChan:
					buf.Write(b.Bytes())
					buffer.PutIoBuffer(b)
				default:
					break
				}
			}
			buf.WriteTo(l)
			buffer.PutIoBuffer(buf)
        }
        // 当一次循环处理完之后，会调用 runtime.Gosched() 主动让出当前协程的 cpu 资源
		runtime.Gosched()
	}
}
```

日志的写入：

```golang
func (l *Logger) Write(p []byte) (n int, err error) {
	// default roller by daily
	if !l.create.IsZero() { // 在上文中提到了  如果配置了l.create 那么说明是需要按照时间静定日志文件滚动
		now := time.Now()
		if (l.create.Unix()+int64(localOffset))/(l.roller.MaxTime) !=
			(now.Unix()+int64(localOffset))/(l.roller.MaxTime) {
			// ignore the rename error, in case the l.output is deleted
			if l.roller.MaxTime == defaultRotateTime { // 默认按照一天的时间进行滚动，这里我们就可以知道，这个滚动就是 修改日志输出文件名
				os.Rename(l.output, l.output+"."+l.create.Format("2006-01-02"))
			} else {
				os.Rename(l.output, l.output+"."+l.create.Format("2006-01-02_15"))
			}
			l.create = now
			//TODO: recover?
			go l.Reopen()
		}
	}
	return l.writer.Write(p)
}
```

# accessLog详细分析

上文中我们详细分析了`ErrorLog`，本质上`ErrorLog` 是用如下

```golang
type SimpleErrorLog struct { // 实现了接口 type ErrorLogger interface
    *Logger
    Formatter func(lv string, alert string, format string) string
    Level     Level
}
```

`SimpleContextLog`

```golang
// SimpleComtextLog is a wrapper of SimpleErrorLog
type SimpleContextLog struct { // 实现了接口  type ContextLogger interface
    *SimpleErrorLog
}
```

```golang
// proxyLogger is a default implementation of ContextLogger
// context will add trace info into formatter
// we use proxyLogger to record proxy events.
type proxyLogger struct { // 实现了接口  type ContextLogger interface
    log.ErrorLogger
}
```

在上文分析中可以知道，在包：`mosn.io/mosn/pkg/log`中的：

* `DefaultLogger` 是： `SimpleErrorLog`
* `Proxy`是： `proxyLogger`

## accesslog 的结构

```golang
// tip 主要用来记录上下游请求的数据信息 具体对应的配置文件的地方 servers->listener->access_logs
// types.AccessLog
type accesslog struct {
    output  string
    entries []*logEntry
    logger  *log.Logger
}
```

`accesslog`是对底层`mosn.io/pkg/log/logger.go: Logger` 的包装。

## Entry 的结构

```golang
type logEntry struct {
    text     string 
    variable variable.Variable // mosn 变量机制，存放一些预定义的一些变量
}
```

## accesslog 的创建

```golang
// tip log.GetOrCreateLogger 使用底层封装好的 logger roller 使用默认的 defaultRoller，默认每天轮转。
// NewAccessLog
func NewAccessLog(output string, format string) (api.AccessLog, error) {
    lg, err := log.GetOrCreateLogger(output, nil)
    if err != nil {
        return nil, err
    }

    entries, err := parseFormat(format) // 解析字符串为： []*logEntry
    if err != nil {
        return nil, err
    }

    l := &accesslog{
        output:  output,
        entries: entries,
        logger:  lg,
    }

    if DefaultDisableAccessLog {
        lg.Toggle(true) // disable accesslog by default
    }
    // save all access logs
    accessLogs = append(accessLogs, l)

    return l, nil
}
```

在文章最前面，我们分析了配置文件，一个`listener`可以配置多个`accesslog`，在`pkg/server/handler.go`中新建了多个`accesslog`。

```golang
// AddOrUpdateListener used to add or update listener
// listener name is unique key to represent the listener
// and listener with the same name must have the same configured address
func (ch *connHandler) AddOrUpdateListener(lc *v2.Listener, updateListenerFilter bool, updateNetworkFilter bool, updateStreamFilter bool) (types.ListenerEventListener, error) {
    // ....
    if al = ch.findActiveListenerByName(listenerName); al != nil { // update
        // ...
    } else { // add
        // listener doesn't exist, add  the listener
        //TODO: connection level stop-chan usage confirm
        listenerStopChan := make(chan struct{})

        //initialize access log
        var als []api.AccessLog

        for _, alConfig := range lc.AccessLogs { // 新建多个 accesslog
            //use default listener access log path
            if alConfig.Path == "" {
                alConfig.Path = types.MosnLogBasePath + string(os.PathSeparator) + lc.Name + "_access.log"
            }

            if al, err := log.NewAccessLog(alConfig.Path, alConfig.Format); err == nil {
                als = append(als, al)
            } else {
                return nil, fmt.Errorf("initialize listener access logger %s failed: %v", alConfig.Path, err.Error())
            }
        }

        l := network.NewListener(lc)

        var err error
        al, err = newActiveListener(l, lc, als, listenerFiltersFactories, networkFiltersFactories, streamFiltersFactories, ch, listenerStopChan)
        if err != nil {
            return al, err
        }
        l.SetListenerCallbacks(al)
        ch.listeners = append(ch.listeners, al)
        log.DefaultLogger.Infof("[server] [conn handler] [add listener] add listener: %s", lc.AddrConfig)
    }
    admin.SetListenerConfig(listenerName, *al.listener.Config())
    return al, nil
}
```

## accesslog 中解析logEntry

`accesslog`中会使用到`mosn`中的变量机制，变量机制是用的go内置的`context`包中的`valueCtx`，如果对context不熟悉先去了解下。

想要了解清楚 `accesslog` 中logEntry的解析过程，我们可以详细的debug单元测试函数： `pkg/log/errorlog_test.go: func TestAccessLog(t *testing.T)`