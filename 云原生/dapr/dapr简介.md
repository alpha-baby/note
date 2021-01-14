### dapr 简介

Dapr(Distributed Application Runtime)

**分布式**应用**运行时**

![](https://tva1.sinaimg.cn/large/008eGmZEly1gmmb5phfdrj30xy0g1q5i.jpg)

---

1. Dapr是什么？
2. Dapr能为我做什么？
3. 展望！

---

## 1 Dapr 是什么?

Dapr is a portable, event-driven runtime that makes it easy for developers to build resilient, microservice stateless and stateful applications that run on the cloud and edge and embraces the diversity of languages and developer frameworks.

Dapr是一个**可移植的**，由**事件驱动的** **运行时**，使**开发人员**可以轻松构建在**云和边缘**上运行并包含**多种语言**和开发人员框架的**弹性**，微服务**无状态和有状态**应用程序。

---

* 分布式程序(Distributed Application)指的是什么？

---

和微服务是一个意思。大的系统分成彼此独立的小的模块，模块和模块之间通过API互相通信，这样每个模块可以用不同的语言开发，一个模块升级的时候不会影响到别的模块。

---

* 云和边缘(cloud and edge)指的是什么？

---

这里的云和边缘指的是Dapr的App可以跑在AWS，Azure，GCP等云服务器上，也可以跑在本地的服务器和远端的物联网终端。

---

事件驱动(event-driven)指的是什么？

---

可以理解成Dapr在没有监听（Listening）到请求到来的时候会一直处于待机的状态，什么也不做，只有监听到请求事件来了才开始处理。

---

可移植(portable)指的是什么？

---

指程序和运行的环境，用的中间件无关。

比如说原来跑在AWS上，现在想跑在Azure上，Nosql数据库原来用redis，现在想用etcd，消息中间件原来用rocketMQ，现在想用kafka，没问题，只要在Dapr设定这边做一下切换，程序无需改动。

---

运行时(runtime)指的是什么？

---

运行时指的是Dapr的运行环境。

Dapr的控制平面（control panel）会单独启动，同时你的程序在启动的时候Dapr会在你的程序上挂一个Sidecar（所谓的边车模式，daprd，runtime），你的程序就可以通过Sidecar和Dapr的控制面。所有挂有Dapr Sidecar的各个微服务之间就可以互相调用了，也可以通过Dapr调用各种中间件。

Note:

---

有弹性(resilient)指的是什么？

---

指的是可以从故障中自动恢复的能力，比如说超时，重试等。不会卡住或陷入一种死循环。

---

无状态和有状态(stateless and stateful)指的是什么？

---

无状态指的是一个微服务经过计算得到结果，返回给调用者以后这个值在微服务这边是不保存的（DB，内存等）。有状态指的是在微服务这边要把这个结果保存起来。

---

支持语言的多样性(the diversity of languages)指的是什么？

---

| Repo | Description |
|:-----|:------------|
| [Go-sdk](https://github.com/dapr/go-sdk) | Dapr SDK for Go
| [Java-sdk](https://github.com/dapr/java-sdk) | Dapr SDK for Java
| [JS-sdk](https://github.com/dapr/js-sdk) | Dapr SDK for JavaScript
| [Python-sdk](https://github.com/dapr/python-sdk) | Dapr SDK for Python
| [Dotnet-sdk](https://github.com/dapr/dotnet-sdk) | Dapr SDK for .NET Core
| [Rust-sdk](https://github.com/dapr/rust-sdk) | Dapr SDK for Rust
| [Cpp-sdk](https://github.com/dapr/cpp-sdk) | Dapr SDK for C++
| [PHP-sdk](https://github.com/dapr/php-sdk) | Dapr SDK for PHP

---

开发人员框架(developer frameworks)指的是什么？

---

指的是Dapr跟框架无关，你可以把各种语言的各种框架（比如java的spring boot框架）和Dapr(API或者SDK)混合使用。

开发人员可以对dapr中的功能进行选择，比如：可以选使用dapr的状态存储，但是不使用dapr的发布订阅.

---

### 1.1 Dapr 的目标

* 使开发人员可以使用任何语言或框架来编写分布式应用程序
* 通过提供最佳实践构建块来解决开发人员构建微服务应用程序时遇到的难题
* 通过开放的API提供一致性和可移植性
* 跨云和边缘与平台无关
* 拥抱可扩展性并提供可插入组件，无需供应商锁定
* 通过高性能和轻量级实现物联网和边缘场景
* 可从现有代码中逐步采用，无运行时依赖性

---

### 1.2 Dapr 的工作原理

Dapr向每个计算单元注入一个边车(容器或进程)。边车与事件触发器进行交互，并通过标准的HTTP或gRPC协议与计算单元通信。这使得Dapr能够支持所有现有和未来的编程语言，而不需要导入框架或库。

---

![k8s部署图](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn10466xlj31rf0u0wpd.jpg)

---

Dapr通过标准的HTTP或gRPC接口提供内置的状态管理、可靠的消息传递（至少一次交付）、触发器和绑定。这使得您可以按照相同的编程模式编写无状态、有状态和类似Actor模式的服务。也可以自由选择一致性模型、线程模型和消息传递模式。

Dapr原生运行在Kubernetes上，在你的机器上以自托管二进制的形式运行，在物联网设备上运行，或者以容器的形式运行，可以注入到云端或企业内部的任何系统中。

---

Dapr使用可插拔的组件状态存储和消息总线（如Redis以及gRPC）来提供广泛的通信方法，包括使用gRPC直接dapr到dapr，以及具有保证交付和至少一次语义的异步Pub-Sub。

---

### 任何语言，任何框架，任何地方

![dapr架构](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1kqx1m0j31jr0u0tiu.jpg)

---

## 2. Dapr能为我做什么？微服务构件

![dapr功能](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1n7m6pnj321y0u0tga.jpg)

---

![状态管理](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1p5zhw6j31l70u00z7.jpg)

---

![服务调用](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1rw0hcfj31jl0u0dli.jpg)

---

![触发器](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1sezk9uj31qq0u044b.jpg)

---

![连接器](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1vsel1dj31kc0u0gt0.jpg)

---

![PubSub](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1wxov0oj31kw0u010q.jpg)

---

![tracing](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1ydlk9yj31hd0u0n5j.jpg)

---

![functions](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn1ztlnamj31jn0u0wiw.jpg)

---

![虚拟Actor](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn20rpftzj31la0u0tiz.jpg)

---

![dapr Actor](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn25zmnn5j31jk0u045a.jpg)

---

![dapr Actor](https://tva1.sinaimg.cn/large/008eGmZEgy1gmn27243y5j31j10u0n4e.jpg)

---

## 3. 展望！

1. 服务调用
2. 中间件组件
3. Functions and Actor