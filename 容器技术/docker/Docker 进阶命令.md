# Docker 进阶

## 镜像操作

### 查看镜像的详细信息

```bash
$ docker image inspect [imageID | image name : image version]
```

### 只查看镜像的ID

```bash
$ docker image ls -q
```

### 镜像的导入和导出

```bash
$ docker image save [imageID | imageName : version] > /local/file
$ docker image load -i /local/file/image.file
```

### 给镜像添加标签

```bash
$ docker image tag [imageID | imageName] tag:version
```

## 容器操作

### 查看容器内部进程信息

```bash
$ docker top [containerID] 
$ docker container top [containerID]
```

### 查看容器的日志

```bash
$ docker container logs [-t -f] [containerID]
```

* -t : 显示时间戳
* -f : 紧跟日志输出（Follow log output）

### 容器和宿主机之间的文件拷贝

```bash
$ docker cp [continer:/path/to/file] [localpath]
$ docker cp [localpath] [continer:/path/to/file]
```

