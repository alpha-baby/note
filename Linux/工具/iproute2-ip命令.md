# iproute2 ip 命令详解

ip 命令主要用来操作 linux 各种网络功能的命令行工具，同时该命令也强大也复杂

## rule 策略路由

也就是命中不同规则，走不同的路由表

**命令格式：**

```bash
Usage: ip rule { add | del } SELECTOR ACTION
       ip rule { flush | save | restore }
       ip rule [ list [ SELECTOR ]]
SELECTOR := [ not ] [ from PREFIX ] [ to PREFIX ] [ tos TOS ]
            [ fwmark FWMARK[/MASK] ]
            [ iif STRING ] [ oif STRING ] [ pref NUMBER ] [ l3mdev ]
            [ uidrange NUMBER-NUMBER ]
            [ ipproto PROTOCOL ]
            [ sport [ NUMBER | NUMBER-NUMBER ]
            [ dport [ NUMBER | NUMBER-NUMBER ] ]
ACTION := [ table TABLE_ID ]
          [ protocol PROTO ]
          [ nat ADDRESS ]
          [ realms [SRCREALM/]DSTREALM ]
          [ goto NUMBER ]
          SUPPRESSOR
SUPPRESSOR := [ suppress_prefixlength NUMBER ]
              [ suppress_ifgroup DEVGROUP ]
TABLE_ID := [ local | main | default | NUMBER ]
```

### 例子1：查看本地所有策略路由规则

```bash
$ ip rule list
0:	from all lookup local
32764:	from all fwmark 0x2 lookup 100
32765:	from all fwmark 0x1 lookup 100
32766:	from all lookup main
32767:	from all lookup default
```

## route 路由表操作

用于 CRUD 路由表

**命令格式：**

```bash
Usage: ip route { list | flush } SELECTOR
       ip route save SELECTOR
       ip route restore
       ip route showdump
       ip route get [ ROUTE_GET_FLAGS ] ADDRESS
                            [ from ADDRESS iif STRING ]
                            [ oif STRING ] [ tos TOS ]
                            [ mark NUMBER ] [ vrf NAME ]
                            [ uid NUMBER ] [ ipproto PROTOCOL ]
                            [ sport NUMBER ] [ dport NUMBER ]
       ip route { add | del | change | append | replace } ROUTE
SELECTOR := [ root PREFIX ] [ match PREFIX ] [ exact PREFIX ]
            [ table TABLE_ID ] [ vrf NAME ] [ proto RTPROTO ]
            [ type TYPE ] [ scope SCOPE ]
ROUTE := NODE_SPEC [ INFO_SPEC ]
NODE_SPEC := [ TYPE ] PREFIX [ tos TOS ]
             [ table TABLE_ID ] [ proto RTPROTO ]
             [ scope SCOPE ] [ metric METRIC ]
             [ ttl-propagate { enabled | disabled } ]
INFO_SPEC := { NH | nhid ID } OPTIONS FLAGS [ nexthop NH ]...
NH := [ encap ENCAPTYPE ENCAPHDR ] [ via [ FAMILY ] ADDRESS ]
      [ dev STRING ] [ weight NUMBER ] NHFLAGS
FAMILY := [ inet | inet6 | mpls | bridge | link ]
OPTIONS := FLAGS [ mtu NUMBER ] [ advmss NUMBER ] [ as [ to ] ADDRESS ]
           [ rtt TIME ] [ rttvar TIME ] [ reordering NUMBER ]
           [ window NUMBER ] [ cwnd NUMBER ] [ initcwnd NUMBER ]
           [ ssthresh NUMBER ] [ realms REALM ] [ src ADDRESS ]
           [ rto_min TIME ] [ hoplimit NUMBER ] [ initrwnd NUMBER ]
           [ features FEATURES ] [ quickack BOOL ] [ congctl NAME ]
           [ pref PREF ] [ expires TIME ] [ fastopen_no_cookie BOOL ]
TYPE := { unicast | local | broadcast | multicast | throw |
          unreachable | prohibit | blackhole | nat }
TABLE_ID := [ local | main | default | all | NUMBER ]
SCOPE := [ host | link | global | NUMBER ]
NHFLAGS := [ onlink | pervasive ]
RTPROTO := [ kernel | boot | static | NUMBER ]
PREF := [ low | medium | high ]
TIME := NUMBER[s|ms]
BOOL := [1|0]
FEATURES := ecn
ENCAPTYPE := [ mpls | ip | ip6 | seg6 | seg6local | rpl | ioam6 | xfrm ]
ENCAPHDR := [ MPLSLABEL | SEG6HDR | SEG6LOCAL | IOAM6HDR | XFRMINFO ]
SEG6HDR := [ mode SEGMODE ] segs ADDR1,ADDRi,ADDRn [hmac HMACKEYID] [cleanup]
SEGMODE := [ encap | encap.red | inline | l2encap | l2encap.red ]
SEG6LOCAL := action ACTION [ OPTIONS ] [ count ]
ACTION := { End | End.X | End.T | End.DX2 | End.DX6 | End.DX4 |
            End.DT6 | End.DT4 | End.DT46 | End.B6 | End.B6.Encaps |
            End.BM | End.S | End.AS | End.AM | End.BPF }
OPTIONS := OPTION [ OPTIONS ]
OPTION := { flavors FLAVORS | srh SEG6HDR | nh4 ADDR | nh6 ADDR | iif DEV | oif DEV |
            table TABLEID | vrftable TABLEID | endpoint PROGNAME }
FLAVORS := { FLAVOR[,FLAVOR] }
FLAVOR := { psp | usp | usd | next-csid }
IOAM6HDR := trace prealloc type IOAM6_TRACE_TYPE ns IOAM6_NAMESPACE size IOAM6_TRACE_SIZE
XFRMINFO := if_id IF_ID [ link_dev LINK ]
ROUTE_GET_FLAGS := [ fibmatch ]
```

### 例子1：查看本地 main 路由表

```bash
$ ip route list table main
default via 192.168.215.1 dev eth0
192.168.215.0/24 dev eth0 proto kernel scope link src 192.168.215.2
```

### 例子2：查看 100 路由表的规则

再介绍 rule 子命令的时候我们可以看到这样的策略规则：

```bash
32764:	from all fwmark 0x2 lookup 100 # 如果数据包被标记成了 0x2 那么就走 100 路由表
32765:	from all fwmark 0x1 lookup 100
```

查看名为 100 的路由表：

```bash
$ ip route list table 100
local default dev lo scope host
```


## netns 操作


```bash
Usage:	ip netns list
	ip netns add NAME
	ip netns attach NAME PID
	ip netns set NAME NETNSID
	ip [-all] netns delete [NAME]
	ip netns identify [PID]
	ip netns pids NAME
	ip [-all] netns exec [NAME] cmd ...
	ip netns monitor
	ip netns list-id [target-nsid POSITIVE-INT] [nsid POSITIVE-INT]
NETNSID := auto | POSITIVE-INT
```

在 `containerd` 或者 `CRI` 的环境中可以通过 `crictl` 工具，查看 `pod`, `container` 等信息，然后通过 `crictl inspectp`, `crictl inspect` 命令查看，

进入某个 pod 或者 container 的 network namespace 中

```bash
root@kind-control-plane:/# crictl inspectp f1b2c3efbd8aa | grep netns
            "path": "/var/run/netns/cni-8743c4b1-ce74-99af-3412-ec93b9310731"
          "Sandbox": "/var/run/netns/cni-8743c4b1-ce74-99af-3412-ec93b9310731"
          "Sandbox": "/var/run/netns/cni-8743c4b1-ce74-99af-3412-ec93b9310731"
root@kind-control-plane:/# ip netns exec cni-8743c4b1-ce74-99af-3412-ec93b9310731 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: eth0@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 22:fc:16:9c:a6:29 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.244.0.3/24 brd 10.244.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20fc:16ff:fe9c:a629/64 scope link
       valid_lft forever preferred_lft forever
root@kind-control-plane:/#
```

`nsenter` 命令也可以用来进入某个 namespace, 比 `ip netns` 命令更加强大，但是该命令需要知道具体某个 `pid`

```bash


```