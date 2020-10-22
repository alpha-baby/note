# MongoDB入门

MongoDB是为快速开发互联网web应用而设计的数据库系统。
MongoDB的设计目标是极简、灵活、作为Web应用的一部分。
MongoDB的数据模型是面向文档的，所谓文档是一种类似于JSON的结构，简单的理解MongoDB这个数据库中存在的是各种JSON。（BSON二进制类型）

## 使用docker安装MongoDB

首先要拉取MongoDB的容器镜像，你可以直接拉取最新的镜像，我这里就拉取4.0版本的镜像。
```bash
$ docker pull mongo:4.0
```

**如果你拉取过慢，可以给docker 配置一个国内的代理，我配置的是阿里的代理**

然后启动容器：

```bash
$ docker run --name mongodb -v /tmp/mongodata:/data/db -d mongo:4.0
```

参数说明：

*  `--name`: 给新启动的容器指定一个名字
* `-p 27017:27017 `：映射容器服务的 27017 端口到宿主机的 27017 端口。外部可以直接通过 宿主机 ip:27017 访问到 mongo 的服务。
* `--auth`：需要密码才能访问容器服务。

查看启动好的容器:

```bash
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
d4b12a3c7be5        mongo:4.0           "docker-entrypoint.s…"   5 seconds ago       Up 4 seconds        27017/tcp           mongodb
```

查看启动日志

```bash
$ docker logs mongodb
2020-01-03T09:19:16.074+0000 I CONTROL  [main] Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'
2020-01-03T09:19:16.081+0000 I CONTROL  [initandlisten] MongoDB starting : pid=1 port=27017 dbpath=/data/db 64-bit host=d4b12a3c7be5
2020-01-03T09:19:16.082+0000 I CONTROL  [initandlisten] db version v4.0.14
....
```

Mongo Express是一个基于网络的MongoDB数据库管理界面，下载mongo-express镜像：

```bash
$ docker pull mongo-express
```

运行mongo-express

```bash
$ docker run --link mongodb:mongo -p 8081:8081 mongo-express
```

然后启动完成了可以在浏览器查看**mongo-express**的界面。

![](https://i.loli.net/2020/01/04/u8YJX4devGBfRsT.png)

## 基本概念

* 数据库（database）
    - 数据库是一个仓库，在仓库中可以存放集合。
* 集合（collection)
    - 集合类似于数组，在集合中可以存放文档。
* 文档（document）
    - 文档数据库中的最小单位，我们`CRUD`操作的对象都是文档。

## mongo shell 

进入mongo shell：

```bash
$ docker exec -it mongodb mongo
```

mongo shell 可以接受javascript语法，如果你熟悉js那么可以执行js代码，比如：

```bash
> print('hello world');
hello world
```

退出mongo shell ：

```bash
> exit;
```

## MongoDB 的基本操作（CRUD）

MongoDB的每篇文档必都有一个唯一的主键，这个主键在每个文档的`_id`这个字段里。
文档的主键支持所有的数据类型(数组除外)。
文档的主键也可以是另外一个文档，这称为复合主键。

在日常的使用中最方便的方式是MongoDB自动的为我们生成文档主键，当我们在新建文档的时候不指定主键，MongoDB驱动会自动的生成一个**对象主键(ObjectID)**来作为文档主键。

**对象主键(ObjectID)**
    - 可快速生成和排序
    - 12字节id
    - 前4字节存储的是对象生成的时间，精确到秒
    - 一般可认为对象主键的顺序就是文档创建的顺序（特殊情况：如果文档在同一秒被存储到数据库，文档的先后无法确认，时间是在客户端上生成的，如果客户端的时间不同也有会造成差别）

### 创建文档

* db.collection.insert()
* db.collection.save()
* 创建多个文档

```bash
# 使用test数据库
> use test
switched to db test
# 查看test数据库中的集合
> show collections
>
# 现在test数据库中还没有集合
```

使用命令：`db.collection.insertOne()` 创建第一个文档

```javascript
// 命令格式
db.<collection>.insertOne(
    <document>,
    {
        writeConcern: <document>
    }
)
```

- `<collection>`: 要替换成文档将要写入的集合的名字
- `<document>`: 要替换成将要写入的文档本身
- `writeConcern`: 定义了本次本当创建操作的安全写级别，安全写级别用来判断一次数据库写入操作是否成功，安全写级别越高，丢失数据的风险就越低，然而写入操作的延迟也可能越高，如果不提供writeConcern文档，mongodb使用默认的安全写级别。

将以下数据写入到数据库文档中：
```javascript
{
    _id: "account1",
    name: "alice",
    balance: 100
}
```

将文档写入到`accounts`集合。
```javascript
> db.accounts.insertOne(
    {
        _id: "account1",
        name: "alice",
        balance: 100
    }
)
// 结果
{ "acknowledged" : true, "insertedId" : "account1" }
```

在返回的结果中：

* `"acknowledged" : true` : 表示安全写级别被启用
* `"insertedId" : "account1"` : 显示了被写入的文档的`_id`

使用命令：`> show collections`,可以看到`test`数据库中有的集合

**accounts**集合是不存在的，当我们向一个不存的集合中插入文档，就会自动的创建集合。

`db.collection.inertMany()` 写入多篇文档时。
如果在顺序写入时，一旦遇到错误，操作便会退出，剩余的文档无论正确与否，都不会被写入。
如果在乱序写入时，即使某些文档造成了错误，剩余的正确的文档任然会被写入。

`db.collection.insert()` 创建单个或多个文档
命令格式如下：

```javascript
db.<collection>.insert(
    <document or array of documents>,
    {
        writeConcern: <document>,
        orderd: <boolean>
    }
)
```

向`accounts`集合中插入文档：

```javascript
> db.accounts.insert(
    {
        name: "george",
        balance: 1000
    }
)
// 结果
WriteResult({ "nInserted" : 1 })
```

 - `"nInserted" : 1`: 表示写入成功的个数

**查看集合存储信息**

```bash
> db.log.stats()          # 查看数据状态
> db.log.dataSize()       # 集合中数据的原始大小
> db.log.totalIndexSize() # 集合中索引数据的原始大小
> db.log.totalSize()      # 集合中索引+数据压缩存储之后的大小
> db.log.storageSize()    # 集合中数据压缩存储的大小
```

## MongoDB 的用户管理

MongoDB数据库默认是没有用户名及密码的，即无权限访问限制。为了方便数据库的管理和安全，需创建数据库用户。

用户中权限的说明 

| 权限                 | 说明                                                                               |
|:---------------------|:-----------------------------------------------------------------------------------|
| Read                 | 允许用户读取指定数据库                                                             |
| readWrite            | 允许用户读写指定数据库                                                             |
| dbAdmin              | 允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问system.profile |
| userAdmin            | 允许用户向system.users集合写入，可以找指定数据库里创建、删除和管理用户             |
| clusterAdmin         | 只在admin数据库中可用，赋予用户所有分片和复制集相关函数的管理权限。                |
| readAnyDatabase      | 只在admin数据库中可用，赋予用户所有数据库的读权限                                  |
| readWriteAnyDatabase | 只在admin数据库中可用，赋予用户所有数据库的读写权限                                |
| userAdminAnyDatabase | 只在admin数据库中可用，赋予用户所有数据库的userAdmin权限                           |
| dbAdminAnyDatabase   | 只在admin数据库中可用，赋予用户所有数据库的dbAdmin权限。                           |
| root                 | 只在admin数据库中可用。超级账号，超级权限                                          |

