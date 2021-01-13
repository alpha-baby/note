### dapr 简介

Dapr(Distributed Application Runtime)

![](https://tva1.sinaimg.cn/large/008eGmZEly1gmmb5phfdrj30xy0g1q5i.jpg)

---

1. Dapr是什么？
2. Dapr能为我做什么？
3. 展望！

---

## 1 Dapr 是什么?

Dapr is a portable, event-driven runtime that makes it easy for developers to build resilient, microservice stateless and stateful applications that run on the cloud and edge and embraces the diversity of languages and developer frameworks.

Dapr是一个可移植的，由事件驱动的运行时，使开发人员可以轻松构建在云和边缘上运行并包含多种语言和开发人员框架的弹性，微服务无状态和有状态应用程序。

---

* 分布式程序(Distributed Application)指的是什么？

---

跟微服务是一个意思。大的系统分成彼此独立的小的模块，模块和模块之间通过API互相通信，这样每个模块可以用不同的语言开发，一个模块升级的时候不会影响到别的模块。

---

* 云和边缘(cloud and edge)指的是什么？

这里的云和边缘指的是Dapr的App可以跑在AWS，Azure，GCP等云服务器上，也可以跑在本地的服务器上。
事件驱动(event-driven)指的是什么？

可以理解成Dapr在没有监听（Listening）到请求到来的时候会一直处于待机的状态，什么也不做，只有监听到请求事件来了才开始处理。
可移植(portable)指的是什么？

就是说写的程序和运行的环境，用的中间件无关。比如说原来跑在AWS上，现在想跑在Azure上，Nosql数据库原来用DynamoDB，现在想用CosmosDB，消息中间件原来用SNS/SQS，现在想用Service Bus，没问题，只要在Dapr设定这边做一下切换，程序无需改动。
运行时(runtime)指的是什么？

运行时指的是Dapr的运行环境。Dapr的Control Plane（不知道怎么翻译，直接用英文，就是Dapr管理用的模块）会单独启动，同时你的程序在启动的时候Dapr会在你的程序上挂一个Sidecar（所谓的边车模式），你的程序就可以通过Sidecar和Dapr的Control Plane联系上。所有挂有Dapr Sidecar的各个微服务之间就可以互相调用了，也可以通过Dapr调用各种中间件。
有弹性(resilient)指的是什么？

指的是可以从故障中自动恢复的能力，比如说超时（Timeout），重试（retry）等。不会卡住或陷入一种死循环。
无状态和有状态(stateless and stateful)指的是什么？

无状态指的是一个微服务经过计算得到结果，返回给调用者以后这个值在微服务这边是不保存的（DB，内存等）。有状态指的是在微服务这边要把这个结果保存起来。
支持语言的多样性(the diversity of languages)指的是什么？

指的是Dapr有各种语言的SDK，比如java，python，go，.net等都支持。
开发人员框架(developer frameworks)指的是什么？

指的是Dapr跟框架无关，你可以把各种语言的各种框架（比如java的spring boot框架）和Dapr(API或者SDK)混合使用。