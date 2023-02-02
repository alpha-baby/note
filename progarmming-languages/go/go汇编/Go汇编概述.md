[转载](https://hopehook.com/post/golang_assembly/)
## 操作方向

plan9 汇编操作数方向 与 intel 汇编方向相反，plan9 是 `从左到右`，intel 是 `从右到左`。

```fallback
// plan9 汇编
MOVQ $123, AX

// intel汇编
MOV RAX, 123
```

## 入栈和出栈

plan9 中栈操作并没有 PUSH POP 指令，而是分别对应 SUB 和 ADD。

SP 是栈顶指针，对应 BP 栈底指针，一般只需要操作 SP 指针，即可完成入栈，出栈操作， 所以 BP 指针用的少。

```
SUBQ $0x18, SP // 对 SP 做减法，入栈
ADDQ $0x18, SP // 对 SP 做加法，出栈
```

## 数据拷贝

MOV 开头的指令是用来移动数据的， 提供的命令比较丰富， 一次移动的数据量有所差异

```fallback
MOVB $1, DI      // MOVB 可以一次移动 1 byte
MOVW $0x10, BX   // MOVW 可以一次移动 2 bytes
MOVD $1, DX      // MOVD 可以一次移动 4 bytes
MOVQ $-10, AX    // MOVQ 可以一次移动 8 bytes
```

## 运算指令

-   ADD 做加法
-   SUB 做减法
-   IMUL 做乘法

```fallback
ADDQ AX, BX      // BX += AX
SUBQ AX, BX      // BX -= AX
IMULQ AX, BX     // BX *= AX
```

## 跳转指令

跳转指令是程序执行流程切换的关键

```fallback
// 无条件跳转
JMP label  // 跳转到标签 可以跳转到同一函数内的标签位置（常用）
JMP addr   // 跳转到地址，地址可为代码中的地址 不过实际上手写不会出现这种东西
JMP 2(PC)  // 以当前 PC 为基础，向前/后跳转 n 行
JMP -2(PC) // 同上

// 有条件跳转
JNZ target // 如果zero flag被set过，则跳转
```

## 常数定义

plan9 汇编中使用 num 表示常数，可以为负，默认情况为 `十进制`，可以使用 0x123 的形式表示 `十六进制`

## 变量声明

汇编中的变量一般是存储在 .rodata 或者 .data 段中的只读值。对应到应用层就是已经初始化的全局的 const、var 变量/常量。

-   DATA 可以声明和初始化一个变量

```fallback
DATA symbol+offset(SB)/width,value
```

上面的语句初始化 symbol+offset(SB) 的数据中 width bytes, 赋值为 value。（SB 的操作都是增地址）

-   GLOBL 声明一个全局变量

如果在 Go package 下，GLOBL 可以导出 DATA 初始化的变量给外部使用

```fallback
GLOBL runtime·tlsoffset(SB), NOPTR, $4
// 声明一个全局变量 tlsoffset，4 byte，没有 DATA 部分，因其值为 0。
// NOPTR 表示这个变量数据中不存在指针，GC不需要扫描。
```

##  Go 的寄存器

Go 汇编为了简化汇编代码的编写，引入了 PC、FP、SP、SB 4 个伪寄存器，加其它的通用寄存器就是 Go 汇编语言对 CPU 的重新抽象。

以 AMD64 环境为例，各个寄存器的用途说明

###  伪 PC 寄存器

-   含义：IP 寄存器的别名，指向指令地址
-   用途：用来指示下一条指令的地址（逻辑地址即偏移量），一般情况下，系统指示对其进行加 1 操作，当遇到转移指令，如 JMP、CALL、LOOP 等时系统就会将跳转到的指令地址保存在 PC 中
-   使用频率：除了个别跳转之外，手写代码与 PC 寄存器打交道的情况较少

### 伪 SB 寄存器

-   含义：可以理解为原始内存，指向全局符号表
-   用途：一般用来声明函数或全局变量
-   使用：foo(SB) 的意思是用 foo 来代表内存中的一个地址。foo(SB) 可以用来定义全局的 function 和数据，foo<>(SB) 表示 foo 只在当前文件可见，跟 C 中的 static 效果类似。此外可以在引用上加偏移量，如 foo+4(SB) 表示 foo+4bytes 的地址
-   使用频率：常用

### BP 寄存器

-   含义：表示函数调用栈的 `起始栈底` (栈的方向从大到小，真 SP 表示栈顶)，记录当前函数栈帧的 `结束位置`
-   用途：保存在进入函数前的栈基址，配合真SP使用，维护函数调用栈关系
-   使用：
    -   函数调用相关的指令会隐式地影响 BP 的值
    -   X86 平台上 BP 寄存器，通常用来指示函数栈的起始位置，仅仅起一个指示作用，现代编译器生成的代码通常不会用到 BP 寄存器
    -   但是可能某些 debug 工具会用到该寄存器来寻找函数参数、局部变量等
    -   因此 amd64 平台上，编译器会在 return address 之后插入 8 byte 来放置 caller BP 寄存器
-   使用频率：一般用的不多，若需要做手动维护调用栈关系，需要用到 BP 寄存器，手动 split 调用栈。

### SP 寄存器

-   含义：
    -   `真SP寄存器` 表示函数调用栈的 `结束栈顶` (栈的方向从大到小，BP表示栈底)，记录当前函数栈帧的 `结束位置`
    -   `伪SP寄存器` 表示本地局部变量 `最高起始地址`
-   用途：
    -   真 SP 一般用于栈分配，栈释放等
    -   伪 SP 一般用于定位局部变量
-   伪 SP 使用：
    -   伪 SP 起始于局部变量的高地址，所以使用时需要使用 `负偏移量`
    -   通过 symbol+offset(SP) 的方式使用，offset 的合法取值是 \[-framesize, 0\)
    -   例如 b-8(SP) 表示局部变量 b 在伪 SP 的第 8 byte 位置
- 真 SP 的使用：
    -   真 SP 起始于函数栈帧的低地址，编译器加减 SP 指针可以实现栈分配和栈释放
    -   栈分配和释放是一次性加减运算就分配好了
-   使用频率：真伪 SP 都常用 (编译器最终都是生成真 SP)

### 伪 FP 寄存器

-   含义：`编译器` 维护了基于 FP 偏移的栈上参数指针，标识参数
-   用途：一般用来标识和访问函数的参数和返回值
-   使用：要访问具体 function 的参数，编译器强制要求必须使用 `标识符前缀` 来访问FP，比如 foo+0(FP) 获取 foo 的第一个参数，foo+8(FP) 获取第二个参数，64 位系统加上偏移量就可以访问更多的参数
-   与伪 SP 寄存器的关系:
    -   伪 FP 是访问入参、出参的基址，一般用 `正向偏移` 来寻址
    -   伪 SP 是访问本地变量的起始基址，一般用 `负向偏移` 来寻址
-   使用频率：常用

### 通用寄存器

-   AX、BX、CX、DX、DI、SI、R8-R15

### MMX 寄存器

-   R0-R7 并不是通用寄存器，它们只是 X87 开始引入的 MMX 指令专有的寄存器

### TLS 伪寄存器

-   该寄存器存储当前 goroutine g 结构地址

## 常见问题

### 1. 如何查看 Go 汇编代码？

对于想要学习 Go 汇编语言的朋友，我们可以翻阅一下 Go 源码，里面就有大量实践中的汇编案例。 另外，我们还可以通过反汇编等手段，来分析自己写的 Go 程序编译后的代码，了解一些底层的机制和原理。

这里简单分享一些获取汇编代码的命令：

-   编译输出

```go
// -N 禁用优化
// -l 禁用内联
// -S 输出汇编代码
go build -gcflags='-N -l -S' main.go

// 等价于
go tool compile -N -l -S main.go
```

-   反汇编

```go
// 编译成 main.o
go tool compile -N -l main.go

// 反汇编
go tool objdump -S main.o
```

-   SSA 分析

通过 SSA 分析生成一个 ssa.html 网页，打开可以查看 Go 程序编译的整个过程，最后一步就是我们要的汇编指令

```fallback
GOSSAFUNC="main" go build main.go
```

### 2. 汇编函数中指定的 framesize 和 argsize 是什么意思?

-   framesize 表示函数的整个栈帧大小
    -   包括作为 callee 的本地局部变量
    -   包括作为 caller 的返回值参数
    -   包括作为 caller 的输入参数
    -   不包括 parent caller BP
    -   不包括 return address 函数返回地址
-   argsize 表示作为 caller，分配的函数入参和返回值的空间大小
    -   当有 NOSPLIT 标识时，可以不写输入参数、返回值占用的大小
    -   可以省略，因为编译器可以从 Go 语言的函数声明中推导出函数参数的大小
-   如果 framesize 大于 0，而且 framepointer enabled，则 BP 寄存器也会压栈，同时真 SP 寄存器向下偏移 framesize 字节，分配栈空间

![02-02-b1KCO4](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2023/02-02-b1KCO4.jpg)

汇编函数定义

### 3. 如何区分真伪寄存器?

-   伪寄存器一般需要一个标识符和偏移量为前缀，如果没有 `标识符前缀` 则是真寄存器
-   (SP)、+8(SP) 没有标识符前缀为真 SP 寄存器，而 a(SP)、b-8(SP) 有标识符为前缀表示伪 SP 寄存器

### 4. AMD64 环境下，FP 和 SP 寄存器的关系？

-   场景
    -   我们假设场景是 caller 调用 callee，framesize 大于 0，BP 寄存器压栈时候的情况
    -   我们限制 NOSPLIT，不允许叶子函数栈分裂
    -   caller 的 FP 指针在上面的高地址处，callee 的真伪 SP 都在低地址处，横跨了 caller 和 callee 两个函数
-   关系
    -   伪FP = 真SP + framesize + 16
        -   arg0+0(FP) = 0(SP) + framesize + 16
        -   说明：这里的 16 字节分别存储的是 8 字节 parent caller BP，以及 8 字节 return address
    -   伪SP = 真SP + framesize
        -   说明：伪SP 此时指向 BP 低地址下面一个位置
    -   伪FP = 伪SP + 16
-   注意事项
    -   伪 SP、伪 FP 寄存器都是基于真 SP 计算好的，方便快捷操作
    -   当真 SP 寄存器被修改的时候，伪 SP、伪 FP 寄存器会发生同样的移动
    -   因此，最好不要修改真 SP，交由编译器处理

![函数调用栈帧](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2023/02-02-Gep0w0.jpg)

函数调用栈帧

### 5. 函数调用过程中栈帧发生了哪些变化？

-   执行 CALL 指令，调用
    -   入栈函数调用后的返回地址 return address（callee 返回到 caller 后，执行的 caller 的后续指令的地址 addr）
    -   跳转到 PC 寄存器指向的指令地址
-   分配好 callee 栈帧
    -   函数调用头部，编译器会插入 3 指令
        -   第一条：`SUBQ $16, SP` 分配 callee 的栈帧空间，将 sp 向下移动 16 字节，这个就是 `callee 的栈顶`
        -   第二条：`MOVQ BP, 8(SP)` 将 caller 的 BP 栈基备份到 return address 下面（低地址处)
        -   第三条：`LEAQ 8(SP), BP` 将 BP 寄存器指向 callee 的栈基（对 0x8(SP) 取地址，这个位置就是 `callee 的栈基`）
-   执行完 callee 函数代码段 TEXT 后续的指令
-   恢复 caller 的栈帧
    -   函数返回前，需要恢复 caller 的栈帧，编译器会插入 2 条指令到 `函数的尾部`
        -   第一条：`MOVQ 8(SP), BP` 恢复 caller 的 BP 栈基地址
        -   第二条：`ADDQ $16, SP` 释放 callee 的栈空间，SP 寄存器自然就恢复到了 caller 当初的位置
-   执行 RET 指令，返回
    -   出栈返回地址 return address
    -   PC 寄存器跳转到 return address
    -   执行 return address 处的指令，caller 得以恢复执行

## 小结

在 Go 的汇编里，提供了很多独特的 `伪寄存器`，帮助用户快捷定位到对应的硬件寄存器、全局变量、函数、协程等，确实很便利。 换个角度来看，如果用户不了解 Go 这些伪寄存器的机制、栈帧布局，那就很难受了。

对于编写和学习 Go 汇编，很多寄存器的操作都是透明的，我们应该重点关心的是函数调用中返回参数、输入参数、本地变量在栈帧的布局。 搞清楚了伪 FP 寄存器、伪 SP 寄存器，就明白了一大半了，编译后生成的汇编指令也会转换为真 SP 寄存器，并不存在任何伪寄存器。

其他的，伪 PC、伪 SB 寄存器、伪 TLS 寄存器等，只要理解即可。BP 寄存器虽然存在感很低，但是对于理解函数栈帧布局还是很有用的。

## 参考资料：

-   [golang asm](https://go.dev/doc/asm)
-   [golang 汇编](https://lrita.github.io/2017/12/12/golang-asm)
-   [肝了一上午的Golang之Plan9入门](https://mp.weixin.qq.com/s/8wnMvROFQkVTKZ-qe4_eqw)

Author hopehook

LastMod 2021-12-30