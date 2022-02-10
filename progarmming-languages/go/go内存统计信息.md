# golang runtime.MemStats

[//]: # ( Source: https://golang.org/pkg/runtime/#MemStats

refer: https://blog.haohtml.com/archives/21685

## MemStats 结构体

```go
// MemStats记录有关内存分配器的统计信息
type MemStats struct {
    // General statistics.
    Alloc uint64
    TotalAlloc uint64
    Sys uint64
    Lookups uint64
    Mallocs uint64
    Frees uint64

    // Heap memory statistics.
    HeapAlloc uint64
    HeapSys uint64
    HeapIdle uint64
    HeapInuse uint64
    HeapReleased uint64
    HeapObjects uint64

    // Stack memory statistics.
    StackInuse uint64
    StackSys uint64

    // Off-heap memory statistics.
    MSpanInuse uint64
    MSpanSys uint64
    MCacheInuse uint64
    MCacheSys uint64
    BuckHashSys uint64
    GCSys uint64
    OtherSys uint64

    // Garbage collector statistics.
    NextGC uint64
    LastGC uint64
    PauseTotalNs uint64
    PauseNs [256]uint64
    PauseEnd [256]uint64
    NumGC uint32
    NumForcedGC uint32
    GCCPUFraction float64
    EnableGC bool
    DebugGC bool

    // BySize reports per-size class allocation statistics.
    BySize [61]struct {
        Size uint32
        Mallocs uint64
        Frees uint64
    }

}
```

可以清楚的看到，统计信息共分了五类:

* 常规统计信息（General statistics）
* 堆内存统计（Heap memory statistics）
* 栈内存统计（Stack memory statistics）
* 堆外内存统计信息（Off-heap memory statistics）
* 垃圾回收器统计信息（Garbage collector statistics）
* 按 per-size class 大小分配统计（BySize reports per-size class allocation statistics）
* 以下按分类对每一个字段进行一些说明，尽量对每一个字段的用处可以联想到日常我们工作中用到的一些方法。

## 常规统计信息（GENERAL STATISTICS）

* Alloc 已分配但尚未释放的字节
* TotalAlloc 已分配（就算释放也不会减少）
* Sys 系统中获取的字节(xxx_sys的统计, 无锁，近似值)
* Lookups runtime执行时的指针查找数（主要在调试runtime内部使用）
* Mallocs 分配堆对象的累计数量，活动对象的数量是Mallocs-Frees
* Frees Frees是释放的堆对象的累计计数

## 分配堆内存统计（HEAP MEMORY STATISTICS）

原子更新或STW

* HeapAlloc 已分配但尚未释放的字节(同上面的alloc一样)
* HeapSys 从os为堆申请的内存大小
* HeapIdle 空闲 spans 字节
* HeapInuse 使用中的最大值
* HeapReleased 操作系统的物理内存大小
* HeapObjects 分配的堆对象总数量

## 栈内存统计（STACK MEMORY STATISTICS）

* StackInuse 在stack span的字节
* StackSys 从os中获取的stack内存

## 堆外内存统计信息（OFF-HEAP MEMORY STATISTICS）

* MSpanInuse 分配的mspan结构的字节
* MSpanSys 从os中获取的用于mspan结构的字节
* MCacheInuse 已分配的mcache结构的字节
* MCacheSys 从os中分配的mcache结构的字节
* BuckHashSys 分析bucket哈希表中的内存字节
* GCSys GC中元数据的字节
* OtherSys 其它堆外runtime分配的字节

## 垃圾回收器统计信息（GARBAGE COLLECTOR STATISTICS）

* NextGC 下次GC目标堆的大小
* LastGC 上次GC完成的时间,UNIX时间戳
* PauseTotalNs 从程序开始时累计暂停时长(STW), 单位纳秒
* PauseNs 最近一次的STW时间缓存区，最近一次暂停是在 PauseNs[(NumGC+255)%256]，通常它是用来记录最近 N%256 次的GC记录。
* PauseEnd 最近GC暂停的缓冲区，缓冲区的存放方式与PauseNs一样。每个GC有多个暂停，记录最后一次暂停
* NumGC 完成的GC数量
* NumForcedGC 记录应用通过调用 GC 函数强制GC的次数
* GCCPUFraction 自程序启动后GC使用CPU时间的分值，其值为0-1之间，0表示gc没有消耗当前程序的CPU。（不包含写屏障的cpu时间）
* EnableGC 启用GC, 值为true，除非使用GOGC=off设置
* DebugGC 当前未使用

**可以看到这些字段的信息还是比较常见的，在我们分析一个程序GC 的时候，经常会用到 GDEBUG=gctrace=1 go run main.go 这个命令，它的输出不正是这几个字段的信息的么？**

```go
func ReadMemStats(m *MemStats) {
    stopTheWorld("read mem stats")
    systemstack(func() {
        readmemstats_m(m)
    })
    startTheWorld()
}
```

源码可知，在收集信息的时候会处于 STW 状态
