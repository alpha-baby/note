# DockerFile 

DockerFile是用来构建Docker镜像的构建文件，是由一系列命令和参数构建成的脚本文件。  

如果你想要从一个基础镜像开始建立一个自定义镜像，可以选择一步一步进行构建，也可以选择写一个配置文件，然后一条命令（`docker build`）完成构建，显然配置文件的方式可以更好地应对需求的变更，这个配置文件就是Dockerfile。

[DockerFile文档](https://docs.docker.com/engine/reference/builder/)


# docker file 体系结构

## 基础

1. 每条保留字指令都必须为大写字母并且后面要跟随至少一个参数
2. 指令按照从上到下，顺序执行
3. `#`表示注释
4. 每条指令都会创建一个新的镜像层，并对镜像进行提交

**DockerFile执行流程**

1. docker 从基础镜像运行一个容器
2. 执行一条指令并对容器作出修改
3. 执行类似docker commit的操作提交一个新的镜像层
4. docker再基于刚提交的镜像运行一个新的容器
5. 执行dockerfile中的下一条指令直到所有指令都执行完成


## docker保留字指令

### FROM

基础镜像，当前新镜像是基于哪个镜像的

### MAINTAINER

镜像维护者的姓名和邮箱

### RUN

容器构建的时候需要额外执行的linux命令

### EXPOSE

当前容器对外暴露出的端口

### WORKDIR

指定在创建容器后，终端默认登陆进来的工作目录，一个落脚点

### ENV

用来在构建镜像过程中设置环境变量

### ADD

将宿主机目录下的文件拷贝进镜像并且ADD命令会自动处理URL和解压tar压缩包

### COPY

类似ADD，拷贝文件和目录到镜像中。
将从构建上下文目录中<源路径>的文件/目录复制到新的一层的镜像内的<目标路径>位置

1. COPY src dest    
2. COPY ["src","dest"]

### VOLUME

容器数据卷，用于数据保存和持久化工作

VOLUNE["dir1","dir2"]

出于可移植性和分享的考虑，用`-v dir:Dir`这种方法不能直接在DockerFile中实现。由于宿主机目录是依赖于特定宿主机的，并不能够保证在所有的宿主机上都存在这样的特定目录。

### CMD

指定一个容器启动时要运行的命令

Dockerfile中可以有多个`CMD`指令，但只有最后一个生效，`CMD`会被docker run之后的参数替换.

`CMD` 指令的格式和 `RUN` 相似,也是两种格式：

* `shell` 格式：`CMD <命令>`
* `exec` 格式：`CMD ["可执行文件"，"参数1"，"参数2"...]`
* 参数列表格式：`CMD ["参数1","参数2"...]` 在指定了`ENTRYPOINT` 指令后，用 `CMD` 指定具体的参数。

### ENTRYPOINT

指定一个容器启动时要运行的命令

`ENTRYPOINT` 的目的和 `CMD` 一样，都是在指定容器启动程序及参数

### ONBUILD

当构建一个被继承的Dockerfile时运行命令，父镜像在被子继承后父镜像的`ONBUILD`被触发，类似于触发器。

# docker build

*`docker build -f [dockerfileDir]`*

 