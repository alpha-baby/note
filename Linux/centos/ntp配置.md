# ntp 

NTP 是网络时间协议 (Network Time Protocol)，它是用来同步网络中各个计算机的时间的协议。

## centos

```bash
yum install -y ntp ntpdate

ntpdate ntp.aliyun.com
 

systemctl start ntpd

systemctl enable ntpd
```