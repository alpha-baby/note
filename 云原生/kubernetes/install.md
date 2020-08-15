# kubetnetes 安装

## 使用kubeeasz工具安装

[kubeasz Github](https://github.com/easzlab/kubeasz/)

>参考文档
>https://github.com/easzlab/kubeasz/blob/master/docs/setup/offline_install.md


### 使用kubeasz安装命令

```bash
export release=2.2.1
curl -C- -fLO --retry 3 https://github.com/easzlab/kubeasz/releases/download/${release}/easzup
chmod +x ./easzup
./easzup -D -d 19.03.5 -k v1.18.2
./easzup -S
docker exec -it kubeasz easzctl start-aio
docker exec -it kubeasz easzctl destroy
```

shell脚本

```shell
#!/bin/sh
export release=2.2.1
curl -C- -fLO --retry 3 https://github.com/easzlab/kubeasz/releases/download/${release}/easzup
chmod +x ./easzup
./easzup -D -d 19.03.5 -k v1.18.2
./easzup -S
docker exec -it kubeasz easzctl start-aio
```