# K8S 集群中的认证、授权与 kubeconfig

Author [xuyasong](http://www.xuyasong.com/?author=1)Posted on [2020年7月6日2020年7月6日](http://www.xuyasong.com/?p=2054)[Leave a comment](http://www.xuyasong.com/?p=2054#respond)

> 转载 http://www.xuyasong.com/?p=2054

*   [1 前言](#i)
*   [2 两种用户](#i-2)
*   [3 三种机制](#i-3)
*   [4 K8S 中的认证](#K8S)
    *   [4.1 X509 client certs](#X509_client_certs)
    *   [4.2 Service Account Tokens](#Service_Account_Tokens)
*   [5 kubeconfig 的生成与含义](#kubeconfig)
    *   [5.1 生成最高权限的 kubeconfig](#_kubeconfig)
        *   [5.1.1 集群参数](#i-4)
        *   [5.1.2 用户参数](#i-5)
        *   [5.1.3 上下文参数](#i-6)
    *   [5.2 kubeconfig 的认证过程](#kubeconfig-2)
    *   [5.3 O 和 CN 的含义](#O_CN)
    *   [5.4 k8s 核心组件的默认权限](#k8s)
*   [6 K8S 中的授权](#K8S-2)
    *   [6.1 Node](#Node)
    *   [6.2 RBAC](#RBAC)
*   [7 K8S 中的准入控制](#K8S-3)
*   [8 证书吊销、过期更换](#i-7)
    *   [8.1 吊销](#i-8)
    *   [8.2 证书续签](#i-9)
*   [9 更换 apiserver 的 ip 或接入 nginx](#_apiserver_ip_nginx)
*   [10 多租户集群中的的用户访问控制](#i-10)
*   [11 其他场景下的认证需求](#i-11)
    *   [11.1 ingress](#ingress)
    *   [11.2 helm](#helm)
*   [12 参考文档](#i-12)

# 前言

K8S 提供了丰富的认证和授权机制，可以满足各种场景细粒度的访问控制。本文会介绍 k8s 中的用户认证、授权机制，并通过例子阐述 kubeconfig 的生成和原理，最后会列举常见的证书问题，如过期、吊销、租户控制等。本文属于科普 + 实践，不涉及 apiserver 中代码实现

# 两种用户

k8s中的客户端访问有两类用户:

* 普通用户（Human User），一般是集群外访问，如 kubectl 使用的证书
* service account: 如集群内的 Pod

有什么区别呢？

* k8s 不会对 user 进行管理，并不存储 user 信息，你也不能通过调用k8s api来增删查这个 user。你可以认为这个 user 指的就是公司内的人员，一般需要对接内部权限系统，user 的增删操作都是在 k8s 外部进行，k8s 只做认证不做管理。
* k8s 会对serviceaccount 进行管理，他的作用是给集群内运行的 pod 提供一种认证的方式，如果你这个 pod 想调用apiserver操作一些资源如获取 node列表，就需要绑定一个serviceaccount账户给自己，并为这个serviceaccount赋予一定的权限，这样就做到了实体和权限的分离，也就是后面会提到的 rbac 授权。

作用范围：

* User独立在 K8S 之外，也就是说User是可以作用于全局的，跨 namespace，并且需要在全局唯一
* ServiceAccount是K8S的一种资源，是存在于某个namespace之中的，在不同namespace中可以同名，代表了不同的资源。

举例说明：

**为 user 生成 kubeconfig**

一个同事张三都想要一份集群的 kubeconfig 用来日常 kubectl 操作集群，但限定只能操作名为 test 的 namespace，公司有独立的权限系统，他的用户 ID 是唯一的，叫zhangsan。接下来手动为这个用户生成 kubeconfig

生成证书：

```json
    {
      "CN": "zhangsan",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "ST": "BeiJing",
          "L": "BeiJing",
          "O": "zhangsan",
          "OU": "cloudnative"
        }
      ]
    }
```

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=demo zhangsan.json | cfssljson -bare zhangsan
```

得到：

* zhangsan.pem
* zhangsan-key.pem

接下来为 zhangsan 授权，首先生成一份角色：test-role, 权限为test 的命名空间下的所有资源的所有操作权限

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
    namespace: test
    name: test-role
rules:
- apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

然后将这个角色role绑定到zhangsan这个 user 上，代表 zhangsan 拥有了这个 role 的权限

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
    name: test-zhangsan
    namespace: test
subjects:
- kind: User
    name: zhangsan
    apiGroup: ""
roleRef:
    kind: Role
    name: test-role
    apiGroup: ""
```

为张三生成专属的 kubeconfig 文件，名为zhangsan.conf

```bash
# set-cluster
kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.pem \
    --embed-certs=true \
    --server=https://xx:6443 \
    --kubeconfig=zhangsan.conf

# set-credentials
kubectl config set-credentials zhangsan \
    --client-certificate=/etc/kubernetes/pki/zhangsan.pem \
    --embed-certs=true \
    --client-key=/etc/kubernetes/pki/zhangsan-key.pem \
    --kubeconfig=zhangsan.conf

# set-context
kubectl config set-context zhangsan@kubernetes \
    --cluster=kubernetes \
    --user=zhangsan \
    --kubeconfig=zhangsan.conf

# set default context
kubectl config use-context zhangsan@kubernetes --kubeconfig=zhangsan.conf

mkdir -p ~/.kube; cp zhangsan.conf ~/.kube/config
```

获取 test 下所有的 pod

```bash
kubectl get pod -n test
```

如果获取其他 namespace 下的pod，则报权限错误  

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwhqqus1fj31j006kace.jpg)

**为 pod 创建 serviceaccount**

以 metrics-server的 pod 为例，需要对 pod、node、ns 等资源进行 get list操作，因此权限配置为：

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
    name: metrics-server
    namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    name: system:metrics-server
rules:
- apiGroups:
    - ""
    resources:
    - pods
    - nodes
    - namespaces
    - nodes/stats
    verbs:
    - get
    - list
    - watch

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
    name: system:metrics-server
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:metrics-server
subjects:
- kind: ServiceAccount
    name: metrics-server
    namespace: kube-system
```

pod 的 yaml 配置中声明serviceAccountName为metrics-server

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
    name: metrics-server
    namespace: kube-system
    labels:
    k8s-app: metrics-server
spec:
    selector:
    matchLabels:
        k8s-app: metrics-server
    template:
    metadata:
        name: metrics-server
        labels:
        k8s-app: metrics-server
    spec:
        serviceAccountName: metrics-server
        containers:
        - name: metrics-server
        resources:
            requests:
            cpu: 50m
            memory: 20Mi
            limits:
            cpu: 200m
            memory: 200Mi
        image: __METRICS_SERVER_IMAGE__
        command:
        - /metrics-server
        - --source=kubernetes.summary_api:''
        imagePullPolicy: Always
```

以上是 user用户使用 kubeconfig、pod 使用 serviceaccount 的示例，pod 使用serviceaccount是比较好理解的，但其实 kubeconfig 也可以直接用serviceaccount来生成，不一定非得用 user，只是大多数情况下，kubeconfig 的管理是和用户的声明周期一致的，即子用户可以申领一份自己的 kubeconfig，管理员可以随时吊销或者禁用子用户 kubeconfig 的效力。这个在后面的”多租户下的kubeconfig“中会提到。

# 三种机制

---

谈 k8s 的认证和访问控制，一般都会看到这张图：

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwhslzfvij319x0lb0v4.jpg)

k8s 中所有的 api 请求都要通过一个 gateway 也就是 apiserver 组件来实现，是集群唯一的访问入口。既然是 gateway，最基础的功能就是 api 的认证 + 鉴权了。对应了图上的步骤1和2，而 k8s 中还提供了第 3 步的 admission Control（准入控制），可以更方便地拦截、校验资源请求。

**三种机制：**

1. 认证：Authentication，即身份认证。检查用户是否为合法用户，如客户端证书、密码、bootstrap tookens和JWT tokens等方式。
2. 鉴权：Authorization，即权限判断。判断该用户是否具有该操作的权限，k8s 中支持 Node、RBAC（Role-Based Access Control）、ABAC、webhook等机制，RBAC 为主流方式
3. 准入控制：Admission Control。请求的最后一个步骤，一般用于拓展功能，如检查 pod 的resource是否配置，yaml配置的安全是否合规等。一般使用admission webhooks来实现

1-2-3 全部通过后api 请求会被处理，在 k8s 中也就意味着资源变更可以落库到 etcd。

# K8S 中的认证

---

上面提到 k8s 并不存储 user，只知道一个 user 名称，因此 user 在访问api 时怎么做的认证？

kubernetes 支持很多种认证机制，包括：

* X509 client certs
* Static Token File
* Bootstrap Tokens
* Static Password File
* Service Account Tokens
* OpenId Connect Tokens
* Webhook Token Authentication
* Authticating Proxy
* Anonymous requests
* User impersonation
* Client-go credential plugins

前面提到的 user 生成 kubeconfig就是X509 client certs方式， 而 metric-server 就是Service Account Tokens方式

## X509 client certs

即客户端证书认证，X509 是一种数字证书的格式标准，是 kubernetes 中默认开启使用最多的一种，也是最安全的一种，api-server 启动时会指定 ca 证书以及 ca 私钥，只要是通过同一个 ca 签发的客户端 x509 证书，则认为是可信的客户端，kubeadm 安装集群时就是基于证书的认证方式。

客户端证书认证叫作 TLS 双向认证，也就是服务器、客户端互相验证证书的正确性，在都正确的情况下协调通信加密方案。apiserver 、controller-manager、scheduler、kubelet 等组件之间的交互，一般也是基于X509的客户端认证方式，目前最常用的 X509 证书制作工具有 openssl、cfssl ，上面生成 kubeconfig 时用到就是 cfssl 工具签发的证书。

还是举个例子，在手动部署 k8s 集群时需要做的证书操作，

`如果你已经熟悉这个过程或者用了 kubeadm 等部署工具，可以跳过这一段。`

1.基础证书生成

**ca-config.json**

创建用来生成 CA 文件的 JSON 配置文件，这个文件后面会被各种组件使用，包括了证书过期时间的配置，expiry字段

```json
{
    "signing": {
    "default": {
        "expiry": "87600h"
    },
    "profiles": {
        "demo": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
        }
    }
    }
}
```

**ca-csr.json**

创建用来生成 CA 证书签名请求（CSR）的 JSON 配置文件

```json
{
    "CN": "demo",
    "key": {
    "algo": "rsa",
    "size": 2048
    },
    "names": [
    {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "demo",
        "OU": "cloudnative"
    }
    ]
}
```

**生成基础 ca 证书**

```bash
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

创建自签名 CA 证书：这里只需要ca-csr.json文件，执行后会生成三个文件：

* ca.csr：证书签名请求，一般用于提供给证书颁发机构，自签的就不需要了
* ca.pem：证书，公共证书
* ca-key.pem：CA密钥

2.生成 apiserver 证书

**apiserver-csr.json**

```json
{
    "CN": "kubernetes",
    "hosts": [
        "127.0.0.1",
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local",
        "172.18.0.1","100.64.230.122","100.75.187.77"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "k8s",
            "OU": "cloudnative"
        }
    ]
}
```

hosts列表不仅包含了三台 master 机器的ip，还包括了 对应的负载均衡的 ip和外网 ip（如果有的话），以及 kubernetes 的 svc IP：172.18.0.1

这个 ip 是 svc ip range 中的第一个 ip，如果没有这个 ip，集群内的 pod 将无法通过 serviceaccount 的形式访问 apiserver 并鉴权，会报证书错误。

**apiserver证书**

```bash
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=demo apiserver-csr.json | cfssljson -bare apiserver
```

创建apiserver 的 CA 证书：这里需要4 个文件

* apiserver-csr.json：apiserver的证书配置
* ca.pem：基础公钥
* ca-key.pem：基础私钥
* ca-config.json：配置文件，如过期时间

执行后会生成三个文件：

* apiserver.csr
* apiserver.pem
* apiserver-key.pem

**使用证书**

```bash
....
--secure-port=6443 \
--service-account-key-file=/etc/kubernetes/pki/ca-key.pem \
--service-cluster-ip-range=172.18.0.0/16 \
--storage-backend=etcd3 \
--tls-cert-file=/etc/kubernetes/pki/apiserver.pem \
--tls-private-key-file=/etc/kubernetes/pki/apiserver-key.pem \
```

## Service Account Tokens

也就是 service account 使用的认证方式。

你会发现x509的认证方式比较复杂，需要做很多证书，如果我在集群中部署了一个 pod，比如一些 operator，想访问apiserver获取集群的一些信息，甚至对集群的资源进行改动，这种认证属于 k8s 管理范畴，因此 k8s 定义了一种资源serviceaccounts来定义一个 pod 应该拥有什么权限

serviceaccounts 是面向 namespace 的，每个 namespace 创建的时候，kubernetes 会自动在这个 namespace 下面创建一个默认的 serviceaccounts，并且这个 serviceaccounts 只能访问该 namespace 的资源。serviceaccounts 和 pod、service、deployment 一样是 kubernetes 集群中的一种资源，用户可以创建自己的serviceaccounts

service account 主要包含了三个内容：namespace、token 和 ca ，

* namespace: 指定了 pod 所在的 namespace
* token: token 用作身份验证
* ca: ca 用于验证 apiserver 的证书

每个 service account 都对应一个 secret，这三个信息就存放在这个 secret 里，以 base64 编码。service account 通过 mount 的方式保存在 pod 的文件系统中，其三者都是保存在 /var/run/secrets/kubernetes.io/serviceaccount/目录下。

# kubeconfig 的生成与含义

---

kubeconfig 是用来访问 k8s 集群的凭证，生成 kubeconfig 的步骤很简单但参数很多，这里以生成 admin 的 kubeconfig 为例，解释各参数的含义。

## 生成最高权限的 kubeconfig

一般情况下集群创建之后，会先生成一份最高权限的 kubeconfig，即管理员角色，可以操作集群的所有资源，并为其他用户创建或删除权限，可以称之为 admin 证书，生成方式是：

**admin-csr.json**

```json
{
    "CN": "kubernetes-admin",
    "hosts": [
        "172.18.0.1","100.64.230.122","100.75.187.77"
    ],
    "key": {
    "algo": "rsa",
    "size": 2048
    },
    "names": [
    {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:masters",
        "OU": "cloudnative"
    }
    ]
}
```

**admin 证书**

```bash
cd /etc/kubernetes/pki; cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=demo admin-csr.json | cfssljson -bare admin
```

生成 admin.conf，即最高权限的 kubeconfig

```bash
# 配置kubernetes集群参数

kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.pem \
    --embed-certs=true \
    --server=https://vip:6443 \
    --kubeconfig=admin.conf


# 配置客户端认证参数
kubectl config set-credentials kubernetes-admin \
    --client-certificate=/etc/kubernetes/pki/admin.pem \
    --embed-certs=true \
    --client-key=/etc/kubernetes/pki/admin-key.pem \
    --kubeconfig=admin.conf


# 设置上下文参数 
kubectl config set-context kubernetes-admin@kubernetes \
    --cluster=kubernetes \
    --user=kubernetes-admin \
    --kubeconfig=admin.conf


# 设置默认上下文
kubectl config use-context kubernetes-admin@kubernetes --kubeconfig=admin.conf


# 将 kubeconfig 拷贝到默认路径~/.kube/下，这是 kubectl 命令寻找 kubeconfig 时的默认路径
# 也可以在 kubectl 中手动指定 kubeconfig 文件。如 kubectl --kubeconfig=zhangsan.conf get cs 
mkdir -p ~/.kube; cp admin.conf ~/.kube/config`
```

### 集群参数

本段设置了所需要访问的集群的信息。

* 使用 set-cluster 设置了需要访问的集群，如上为 kubernetes 这只是个名称，实际为 –server 指向的 apiserver 所在的集群
* –certificate-authority 设置了该集群的公钥
* –embed-certs 为 true 表示将 –certificate-authority 证书写入到 kubeconfig 中
* –server 则表示该集群的 apiserver 地址

### 用户参数

本段主要设置用户的相关信息，主要是用户证书。

* 用户名: zhangsan
* 证书: /etc/kubernetes/ssl/zhangsan.pem
* 私钥: /etc/kubernetes/ssl/zhangsan-key.pem

```bash
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=demo zhangsan.json | cfssljson -bare zhangsan
    
    得到：
        
    * zhangsan.pem
    * zhangsan-key.pem
```

这一步操作是指客户端的证书首先要经过集群 CA 的签署，否则不会被集群认可，认证就失败。

此处使用的是 客户端 x509 认证方式，也可以使用token认证，如kubelet的 TLS Boostrap机制下的bootstrapping 使用的就是 token 认证方式

### 上下文参数

集群参数和用户参数可以同时设置多对，而上下文参数就是集群参数和用户参数关联起来。

上面的上下文名称为 kubenetes，集群为 kubenetes(apiserver 地址对应的集群)，用户为zhangsan，表示使用 zhangsan 的用户凭证来访问 kubenetes 集群

最后使用 `kubectl config use-context kubernetes` 来使用名为 kubenetes 的环境项来作为配置。

如果配置了多个环境项，可以通过切换不同的环境项名字来访问到不同的集群环境。

## kubeconfig 的认证过程

正向生成 kubeconfig 我们已经做完了，apiserver 认证请求时，如何解析 kubeconfig 文件的内容呢？

我们可以看下 kubeconfig 的内容：

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://xx:6443
    name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
    name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
    user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

除了 context，里面有三个证书字段，都是 base64 编码后的内容

* certificate-authority-data: server 端的证书，用于验证 apiserver 的合法性
* client-certificate-data: 客户端证书
* client-key-data: 客户端私钥

可以提取出来 certificate-authority-data 的内容放到一个文件cert.txt，然后base64解码

```bash
cat cert.txt | base64 -d 
```

certificate-authority-data：

得到的内容其实就是 ca.pem 即服务端证书，apiserver 的证书也是基于ca.pem签发，因为 TLS 是双向认证，apiserver 在认证 kubectl请求时，kubectl 也需要验证 apiserver 的证书，防止中间人攻击，验证的字段就是certificate-authority-data

client-certificate：

因为 k8s 没有 user 这种资源，因此在使用 kubeconfig 访问时，身份信息就“隐藏”在client-certificate的数据中，我们来查看一下。

将 kubeconfig 中的client-certificate-data的内容放在一个文件 client.txt 中，然后解码：

```bash
cat client.txt | base64 -d > admin.pem
```

查看证书内容：

```bash
    cfssl certinfo -cert admin.pem
```

```json
{
    "subject": {
    "common_name": "kubernetes-admin",
    "country": "CN",
    "organization": "system:masters",
    "organizational_unit": "cloudnative",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
        "CN",
        "BeiJing",
        "BeiJing",
        "system:masters",
        "cloudnative",
        "kubernetes-admin"
    ]
    },
    "issuer": {
    "common_name": "kubernetes",
    "country": "CN",
    "organization": "k8s",
    "organizational_unit": "cloudnative",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
        "CN",
        "BeiJing",
        "BeiJing",
        "k8s",
        "cloudnative",
        "kubernetes"
    ]
    },
    "serial_number": "566012679603493454812450131987428233530903130206",
    "sans": [
    "172.18.0.1"
    ],
    "not_before": "2020-06-25T01:50:00Z",
    "not_after": "2030-06-23T01:50:00Z",
    "sigalg": "SHA256WithRSA",
    "authority_key_id": "DA:2B:A9:AE:AA:89:19:B7:0D:5F:FA:8B:1C:2D:EE:5D:EB:6E:D5:CB",
    "subject_key_id": "FC:38:3A:C0:A4:E9:A6:41:16:24:AA:E6:1C:9C:7F:46:EF:42:61:08",
    "pem": xxx
```

从输出内容可以看到Subject: organization=system:masters, common_name=kubernetes-admin

apiserver 验证、解析请求，得到 system:masters 的http上下文信息，并传给后续的authorizers来做权限校验。

## O 和 CN 的含义

“O”：Organization, apiserver接到请求后从证书中提取该字段作为请求用户所属的组 (Group)  
“CN”：Common Name，apiserver从证书中提取该字段作为请求的用户名 (User Name)

在admin-csr.json中， admin使用了system:masters作为组 (Group)

k8s 预定义了 RoleBinding:cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予了调用 k8s 相关 API 的权限，权限极高。

即：

* Group: system:masters
* ClusterRole: cluster-admin
* ClusterRoleBinding: cluster-admin

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi1l8a7bj31260mw77s.jpg)

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi1yslwzj315y0k0wim.jpg)

### k8s 核心组件的默认权限

* admin权限： system:masters组，clusterrole 和 rolebinding 都叫 cluster-admin
* kubelet: system:nodes组，clusterrole 和 rolebinding 都叫system:nodes，下同
* kube-proxy: system:kube-proxy组
* scheduler: system:kube-scheduler组
* controller-manager: system:kube-controller-manager组

对应关系如图所示  

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi2e63eoj30qw0cumzm.jpg)

即 k8s 所有自身组件使用的权限都是基于内置的 clusterrole，生成出来的 kubeconfig 被各组件进程使用，权限都是默认已有 role，如果希望自己创建 role ，就要使用 rbac 授权了

至此，我们应该知道了kubeconfig 的生成流程、验证方式，以及为什么采用了 admin.conf 作为kubeconfig，kubectl就能拥有最高权限。下面是一幅示意图

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi2k66qqj30sk0aqdgu.jpg)

# K8S 中的授权

---

无论是 user的x509认证 还是 service account的 token认证，认证完后，都要到达第 2 步：授权，  
K8S 目前支持了如下四种授权机制：

* Node
* ABAC
* RBAC
* Webhook

用的最多的就是 RBAC，即基于角色做权限控制。

## Node

仅 v1.7 版本以上支持 Node 授权，配合 NodeRestriction 准入控制来限制 kubelet，使其仅可访问 node、endpoint、pod、service 以及 secret、configmap、pv、pvc 等相关的资源，在 apiserver 中使用以下配置来开启 node 的鉴权机制：

```bash
    KUBE_ADMISSION_CONTROL="...,NodeRestriction,..."
    
    KUBE_API_ARGS="...,--authorization-mode=Node,..."
```

## RBAC

RBAC（Role-Based Access Control）是 kubernetes 中基于角色的访问控制，通过自定义角色并将角色和特定的 user，group，serviceaccounts 关联起来达到权限控制的目的。

RBAC 中有三个比较重要的概念：

* Role: 角色，它其实是一组规则，定义了一组对 Kubernetes API 对象的操作权限；
* Subject: 被作用者，包括 user、group、service account，通俗来讲就是认证机制中所识别的用户；
* RoleBinding: 定义了“被作用者”和“角色”的绑定关系，也就是将用户以及操作权限进行绑定；

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi3hl149j31sg0nq0xb.jpg)

RBAC 其实就是通过创建角色(Role），通过 RoleBinding 将被作用者（subject）和角色（Role）进行绑定。下图是 RBAC 中的几种绑定关系：

![](https://tva1.sinaimg.cn/large/0081Kckwly1glwi42ksfwj30ql0dv414.jpg)

示例：

role:

```yaml
role: 对 Pods 的读取权限

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    namespace: default
    name: pod-reader
rules:
- apiGroups: [""] # "" 指定核心 API 组
    resources: ["pods"]
    verbs: ["get", "watch", "list"]


RoleBinding: 使得用户 "jane" 能够读取 "default" 命名空间中的 Pods

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: read-pods
    namespace: default
subjects:
- kind: User
    name: jane # Name is case sensitive
    apiGroup: rbac.authorization.k8s.io
roleRef:
    kind: Role #this must be Role or ClusterRole
    name: pod-reader # 这里的名称必须与你想要绑定的 Role 或 ClusterRole 名称一致
    apiGroup: rbac.authorization.k8s.io
```

clusterrole:

```yaml
ClusterRole: 对某命名空间下的 Secrets 的读取操，或者跨所有命名空间执行授权,取决于它是如何绑定的

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    # 此处的 "namespace" 被省略掉是因为 ClusterRoles 是没有命名空间的。
    name: secret-reader
rules:
- apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "watch", "list"]

RoleBinding 也可以引用 ClusterRole，对 ClusterRole 所定义的、位于 RoleBinding 命名空间内的资源授权。 这可以允许管理者在 整个集群中定义一组通用的角色，然后在多个命名空间中重用它们。

apiVersion: rbac.authorization.k8s.io/v1
# 这个角色绑定允许 "dave" 用户在 "development" 命名空间中有读取 secrets 的权限。 
kind: RoleBinding
metadata:
    name: read-secrets
    namespace: development # 这里只授予 "development" 命名空间的权限。
subjects:
- kind: User
    name: dave # 名称区分大小写
    apiGroup: rbac.authorization.k8s.io
roleRef:
    kind: ClusterRole
    name: secret-reader
    apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
# 这个集群角色绑定允许 "manager" 组中的任何用户读取任意命名空间中 "secrets"。
kind: ClusterRoleBinding
metadata:
    name: read-secrets-global
subjects:
- kind: Group
    name: manager # 名称区分大小写
    apiGroup: rbac.authorization.k8s.io
roleRef:
    kind: ClusterRole
    name: secret-reader
    apiGroup: rbac.authorization.k8s.io
```

权限声明：

```yaml
rules:
- apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list"]
```

* apiGroups为“”代表所有核心资源即 v1 group
* apiGroups为“*”代表所有group
* 指定 pod 下的子对象如 kubectl logs xx，在resources中写为pods/log
* 对于 CRD 的权限可以定义为：

```yaml
rules:
- apiGroups: ["stable.example.com"]
    resources: ["crontabs"]
    verbs: ["get", "list", "watch"]
```

deployment、sts 等不在核心组，

```yaml
rules:
- apiGroups: ["extensions", "apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

以 prometheus pod 所需要的权限为例：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    name: prometheus
rules:
- apiGroups: [""]
    resources:
    - configmaps
    - secrets
    - nodes
    - pods
    - nodes/proxy
    - services
    - resourcequotas
    - replicationcontrollers
    - limitranges
    - persistentvolumeclaims
    - persistentvolumes
    - namespaces
    - endpoints
    verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
    resources:
    - daemonsets
    - deployments
    - replicasets
    - ingresses
    verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
    resources:
    - daemonsets
    - deployments
    - replicasets
    - statefulsets
    verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
    resources:
    - cronjobs
    - jobs
    verbs: ["get", "list", "watch"]
- apiGroups: ["autoscaling"]
    resources:
    - horizontalpodautoscalers
    verbs: ["get", "list", "watch"]
- apiGroups: ["policy"]
    resources:
    - poddisruptionbudgets
    verbs: ["get", list", "watch"]
- nonResourceURLs: ["/metrics"]
    verbs: ["get"]
```

# K8S 中的准入控制

---

准入控制是请求的最后一个步骤，准入控制有许多内置的模块，可以作用于对象的 “CREATE”、”UPDATE”、”DELETE”、”CONNECT” 四个阶段。在这一过程中，如果任一准入控制模块拒绝，那么请求立刻被拒绝。一旦请求通过所有的准入控制器后就会写入 etcd 中。

准入控制是在 apiserver 中进行配置启用的：

```bash
KUBE_ADMISSION_CONTROL="--enable-admission-plugins=NamespaceLifecycle,LimitRanger,...MutatingAdmissionWebhook,ValidatingAdmissionWebhook,NodeRestriction..."
```

kubectl api-versions |grep admission 来确认是否开启“admissionregistration.k8s.io/v1beta1”

准入控制的配置是有序的，不同的顺序会影响 kubernetes 的性能。若需要对 kubernetes 中的对象做一些扩展，可以使用准入控制，比如：创建 pod 时添加 initContainer 或者校验字段等。准入控制最常使用的扩展方式就是 admission webhooks，分两种

* MutatingAdmissionWebhook：在对象持久化之前进行修改
* ValidatingAdmissionWebhook：在对象持久化之前进行

istio就是通过 mutating webhooks 来自动将Envoy这个 sidecar 容器注入到 Pod 中去的：https://istio.io/docs/setup/kubernetes/sidecar-injection/。

admission webhooks是同步调用，需要部署webhook server，并创建对象ValidatingWebhookConfiguration 或 MutatingWebhookConfiguration来指向自己的 server，以ValidatingAdmissionWebhook为例：

部署 webhook：

```yaml
apiVersion: v1
kind: Pod
metadata:
    labels:
    role: webhook
    name: webhook
spec:
    containers:
    - name: webhook
        image: example-webhook:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort:8000
---
apiVersion: v1
kind: Service
metadata:
    labels:
    role: webhook
    name: webhook
spec:
    ports:
    - port: 443
        targetPort: 8000
    selector:
    role: webhook
```

配置：ValidatingWebhookConfiguration

```yaml
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingWebhookConfiguration
metadata:
    name: config1
externalAdmissionHooks:
    - name: podimage.k8s.io
    rules:
        - operations:
            - CREATE
        apiGroups:
            - ""
        apiVersions:
            - v1
        resources:
            - pods
    failurePolicy: Ignore
    clientConfig:
        caBundle: xxxx
        service:
        namespace: default
        name: webhook
```

你需要等待几秒，然后通过通过Deployment或者直接创建Pod，这时创建Pod的请求就会被apiserver拦住，调用ValidatingAdmissionWebhook进行检查是否Admit通过。比如，上面的example-webhook是检查容器镜像是否以”gcr.io”为前缀的。

示例中的 webhook逻辑比较简单，只是检查下 image name，然后启动 http server

```go
// only allow pods to pull images from specific registry.
func admit(data []byte) *v1alpha1.AdmissionReviewStatus {
    ar := v1alpha1.AdmissionReview{}
    if err := json.Unmarshal(data, &ar); err != nil {
        glog.Error(err)
        return nil
    }
    // The externalAdmissionHookConfiguration registered via selfRegistration
    // asks the kube-apiserver only sends admission request regarding pods.
    podResource := metav1.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"}
    if ar.Spec.Resource != podResource {
        glog.Errorf("expect resource to be %s", podResource)
        return nil
    }

    raw := ar.Spec.Object.Raw
    pod := v1.Pod{}
    if err := json.Unmarshal(raw, &pod); err != nil {
        glog.Error(err)
        return nil
    }
    reviewStatus := v1alpha1.AdmissionReviewStatus{}
    for _, container := range pod.Spec.Containers {
        // gcr.io is just an example.
        if !strings.Contains(container.Image, "gcr.io") {
            reviewStatus.Allowed = false
            reviewStatus.Result = &metav1.Status{
                Reason: "can only pull image from grc.io",
            }
            return &reviewStatus
        }
    }
    reviewStatus.Allowed = true
    return &reviewStatus
}

func serve(w http.ResponseWriter, r *http.Request) {
    var body []byte
    if r.Body != nil {
        if data, err := ioutil.ReadAll(r.Body); err == nil {
            body = data
        }
    }

    // verify the content type is accurate
    contentType := r.Header.Get("Content-Type")
    if contentType != "application/json" {
        glog.Errorf("contentType=%s, expect application/json", contentType)
        return
    }

    reviewStatus := admit(body)
    ar := v1alpha1.AdmissionReview{
        Status: *reviewStatus,
    }

    resp, err := json.Marshal(ar)
    if err != nil {
        glog.Error(err)
    }
    if _, err := w.Write(resp); err != nil {
        glog.Error(err)
    }
}

func main() {
    flag.Parse()
    http.HandleFunc("/", serve)
    clientset := getClient()
    server := &http.Server{
        Addr:      ":8000",
        TLSConfig: configTLS(clientset),
    }
    go selfRegistration(clientset, caCert)
    server.ListenAndServeTLS("", "")
}
```

AdmissionWebhook 与 Initializers 的区别：

二者都能实现动态可扩展载入admission controller， Initializers是串行执行，在高并发场景容易导致对象停留在uninitialized状态，影响继续调度。 Alpha Initializers特性在k8s 1.14版本被移除了，官方更推荐AdmissionWebhook；MutatingAdmissionWebhook是串行执行，ValidatingAdmissionWebhook是并行执行，性能更好。

# 证书吊销、过期更换

---

对于kubeconfig 这种 x509证书来说，只要证书不泄露，可以认为是很安全的。但是颁发证书容易，却没有很好的方案注销证书、续期证书

## 吊销

想一下如果某个核心成员离职，该如何回收他的admin kubeconfig证书？或者不小心把 kubeconfig 泄露，如何让这个 kubeconfig 无效呢？

先看下封禁手段：

如果是离职，且 k8s 集群在内网环境，就算他把证书带出公司也没关系，毕竟有内网访问限制。但如果是云上 k8s 集群，且开放了公网的入口，那么安全风险就很高了，kubeconfig 只是一个文件，你无法通过限制 ip 来源来封禁。

如果是转岗，封禁就比较困难了，仍然在内网环境，且 kubeconfig 一般在办公电脑上使用，即办公网络到服务内网，通过来源封禁是不可能的。

再看下 证书吊销：

kubeconfig 证书不支持吊销，参考 [ISSUE](https://github.com/kubernetes/kubernetes/issues/18982)。准确的说 k8s 没有实现CRL（证书吊销列表）或 OCSP（在线证书状态协议），并没有一个统一的地方管理这些证书，因此如果您的密钥被盗用，Kubernetes也无法在身份验证层知道

如何解决这种问题：

1. 重新签发证书，涉及到apiserver 等组件的重启
2. 如果用了 rbac，封禁这个角色的权限

如何预防这种问题:

1. 重要：不要使用最高权限的证书，不要使用自带权限的证书如 system:master，这种只适合kubelet 等组件使用，不适合用来签发 kubeconfig
2. 无论是用 user 还是 service account 来生成kubeconfig，都使用 rbac 来授权，这样就算 kubeconfig 丢失，也可以解除 clusterrolebinding来吊销权限。即管理给用户的授权，就变成管理clusterrolebinding了
3. 证书的过期时间设置的短一点，如 1 个月就失效，将影响范围降低
4. 合理规划主账号和子账户，如主账户只允许有一份 admin 证书，其他子用户全部基于 rbac 来操作，甚至主账户也可以用 rbac 来操作，只是权限特别大而已
5. 集成外部认证系统

证书之所以无法吊销，是因为证书没有统一的认证中心，换句话，K8S只是定义了一些角色，并没有实现用户管理、权限管理，因此专业的人做专业的事，接入认证系统才是生产环境严肃认真的解决方案。

Kubernetes支持集成第三方Id Provider（IdP），主流的如AD、LADP以及OpenStack Keystone等。一般都是基于 OpenID Connect（OIDC）Token 的认证和授权。

当前支持OpenID Connect的产品有很多，如：

* Keycloak
* UAA
* Dex
* OpenUnison
* 云厂商

基于 Keycloak 进行 Kubernetes 身份认证和 RBAC 鉴权，可以参考这个[文章](https://www.ibm.com/developerworks/cn/cloud/library/cl-lo-openid-connect-kubernetes-authentication2/index.html)

## 证书续签

证书配置中有一个字段：”expiry”: “87600h”代表了证书的过期时间，到期后证书认证会失败。

kubeadm 创建的 Kubernetes 集群， apiserver、controller-manager、kubelete 等组件的证书默认有效期只有一年。

因为 k8s 版本迭代很快，官方推荐一年之内至少用 kubeadm 更新一次 Kubernetes 版本，同时会自动更新证书。

查看根 CA 证书的有效期，默认为 10 年：

```bash
cd /etc/kubernetes/pki
ls | grep ca.crt | xargs -I {} openssl x509 -text -in {} | grep "Not After"
```

查看当前证书有效期

```bash
kubeadm alpha certs check-expiration
```

重新签发证书:续签全部证书

```bash
    kubeadm alpha certs renew all
```

也可以局部进行续签

```txt
    如apiserver-etcd-client 、apiserver-kubelet-client、apiserver、etcd-healthcheck-client、etcd-peer、etcd-server、front-proxy-client
    
    kubeadm alpha certs renew apiserver-etcd-client
    
```

如果不是 kubeadm 创建的集群，需要手动重新生成所有组件的证书

kubelet 从 v1.8.0 开始支持证书轮换，当证书过期时，可以自动生成新的密钥，并从 Kubernetes API 申请新的证书。

```bash
1.配置kube-controller-manager支持轮换
kube-controller-manager --experimental-cluster-signing-duration=87600h \
                --feature-gates=RotateKubeletClientCertificate=true \
                ...

2.配置kubelet 证书
# Refer https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#approval

3.配置 kubelet 的启动参数
kubelet --feature-gates=RotateKubeletClientCertificate=true \
                --cert-dir=/var/lib/kubelet/pki \
                --rotate-certificates \
                --rotate-server-certificates \
                ...
```

# 更换 apiserver 的 ip 或接入 nginx

---

如果因为机器故障，需要更换 apiserver 机器，则最好保持 ip 不变，否则证书需要重签，因为证书文件中声明了机器 ip和负载均衡 ip，如果访问时只用到了负载均衡 ip，那么机器 ip 可以不用声明，也不用担心机器更换问题。

apiserver 接入 nginx

使用 nginx 的 passthrough，即 4 层转发 ssl 请求（配置简单，不需要apiserver证书）

```bash
stream {
    upstream demo {
        server vip:6443 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 6443;
        proxy_pass demo;
        proxy_next_upstream on;
    }
}
```

方法二： 使用七层正常的 http 转发

```bash
    upstream master {
        server vip:6443;
    }
    
    server {
        listen      6443;
        server_name _;
    
        location / {
            proxy_pass                    https://master;
            proxy_ssl_certificate         /etc/kubernetes/pki/admin.pem;
            proxy_ssl_certificate_key     /etc/kubernetes/pki/admin-key.pem;
            proxy_ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
            proxy_ssl_trusted_certificate /etc/kubernetes/pki/ca.pem;
            proxy_set_header Connection $http_connection;
            proxy_http_version 1.1;
    
            proxy_ssl_verify        off;
            proxy_ssl_session_reuse on;
        }
    }
```

# 多租户集群中的的用户访问控制

---

rbac 权限控制是多租户集群中最基础的隔离手段，如基于 namespace 做租户隔离：

企业内部集群：也就是公司内的集群，是很多 k8s 客户的使用模式，因为集群在公司内网环境，网络风险可控，因此一般通过 namespace 对部门或产品线做隔离，如：

* 集群管理员：admin 角色，最高权限，可以扩、缩节点、升级集群，负责分配PV、租户等全局资源，一般是集群负责人。
* 租户管理员：op 角色，租户内（namespace）的最高权限，管理租户内的 rbac 权限、存储、计算资源等
* 普通用户：rd 角色，使用权限，根据开发测试角色不同，功能不同，可能会限制get/list/edit 等权限。

namespace 名一般和部门 id 是一致的，方便对接内部权限系统如 SSO，用户登录后只能看到自己的 ns 下的业务 pod，同时可以下载自己的 kubeconfig 文件。

因为是通过 namespace 做 rbac 权限上的隔离，因此网络层面也要隔离 namespace，禁止互访，如果是跨租户的访问需要开放白名单。而存储和主机特权的隔离需要根据业务来决定，如seccomp/AppArmor/SELinux等是否允许业务使用。

一般情况下，namespace 的权限隔离能满足大多数企业 k8s 的需求，也是很多 paas 平台的租户实现方式。

saas & serveless 平台：一般出现在公有云上，该场景下用户没有 k8s 的概念，且不同的服务可以混布在不同的 namespace，如函数计算、AI 离线计算等，你只需要在 saas 控制台上点击部署 wordpress，选择软件版本，就能得到一个完整的博客平台，不需要关心后面的调度逻辑。

这种混布的业务如果有较高的安全需求，k8s 原生是无法满足的，还需要使用安全容器如 kata在容器运行时来强化租户安全。

# 其他场景下的认证需求

---

## ingress

除了 k8s 集群的认证，ingress 也需要 https 证书，而 ssl 证书的续期管理都是一件麻烦事，如果你用的是云厂商，可以直接在云上购买 ssl 证书并绑定域名，然后通过 ingress-controller 实现 ingress 的功能，续签和证书管理都在云上进行，不需要自己关心

如果你觉得正规的 ca证书太贵，想用 Let’s Encrypt 等签发方式，又觉得续签麻烦，可以使用Cert manager来管理你的证书实现证书自动续签。

cert-manager + nginx-ingress-controller 结合可以参考这个文章：https://cert-manager.io/docs/tutorials/acme/ingress/

## helm

在 helm2 中，helm 操作需要配合集群内部署 tiller 的 pod 来负责资源的创建，因此 tiller 需要赋予一定的权限，一般为了简单会为 tiller 的 pod 赋予 cluster-admin 的最高权限

```bash
    kubectl create serviceaccount tiller --namespace kube-system
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
    name: tiller
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v11
kind: ClusterRoleBinding
metadata:
    name: tiller
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
subjects:
    - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

tiller pod 运行在kube-system 下，拥有集群所有ns、所有资源的操作权限，不过你也可以限定tiller的使用范围，比如只能在特定的 namespace 下工作，如：

在特定 namespace 中部署 tiller，并仅限于在该 namespace 中部署资源

```bash
    kubectl create namespace tiller-world
    kubectl create serviceaccount tiller --namespace tiller-world
```

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v11
metadata:
    name: tiller-manager
    namespace: tiller-world
rules:
- apiGroups: ["","extensions","apps"]
    resources: ["*"]
    verbs: ["*"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v11
metadata:
    name: tiller-binding
    namespace: tiller-world
subjects:
- kind: ServiceAccount
    name: tiller
    namespace: tiller-world
roleRef:
    kind: Role
    name: tiller-manager
    apiGroup: rbac.authorization.k8s.io
```

运行 helm init 来在 tiller-world namespace 中安装 Tiller

```bash
helm init --service-account tiller --tiller-namespace tiller-world
```

而在 helm3 中已经不需要 tiller 这个组件，只需要一个 helm 二进制，因此helm 命令使用的 kubeconfig 的权限，也就决定了能够在哪个 namespace 操作什么资源，helm 权限和 kubectl 统一，更加方便。

# 参考文档

---

* https://blog.tianfeiyu.com/2019/08/18/k8s_auth_rbac/
* https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
* https://pdf.us/2019/03/21/3061.html
* https://www.infoq.cn/article/NyjadtOXDemzPWyRCtdm
* https://www.cncf.io/wp-content/uploads/2018/07/RBAC-Online-Talk.pdf
* https://www.kubernetes.org.cn/4061.html
* https://zhangchenchen.github.io/2017/08/17/kubernetes-authentication-authorization-admission-control/
* http://dockerone.com/article/9561
* https://www.tremolosecurity.com/kubernetes-dont-use-certificates-for-authentication/
* https://help.aliyun.com/document_detail/119596.html?spm=a2c4g.11186623.6.603.2ce12ce7vL1dsQ
* https://kubernetes.io/zh/docs/reference/access-authn-authz/node/
* https://www.youtube.com/watch?v=LgXRdfSqKj0
* https://www.youtube.com/watch?v=CnHTCTP8d48
* https://kubernetes.io/zh/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
* https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/

Tags: [k8s](http://www.xuyasong.com/?tag=k8s)
