# gitlab + gitlab-runner 集成 CICD

## 1 gitlab-runner 安装

* 1.1 下载执行文件

```
# Linux x86-64
sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

# Linux x86
sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-386

# Linux arm
sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm
```

* 1.2 设置执行权限

```
sudo chmod +x /usr/local/bin/gitlab-runner
```

* 1.3 创建 GitLab CI 用户

```
useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
```

* 1.4 运行服务

```
gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
gitlab-runner start
```

## 2 gitlab-runner 注册

### 2.1 获取 Gitlab `注册令牌`

**打开 gitlab 项目 -> 设置 -> CI / CD -> Runners 设置**

![gitlab-settings](https://upload-images.jianshu.io/upload_images/13859457-13f2ce49905e47b5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![tokon](https://upload-images.jianshu.io/upload_images/13859457-da9fe9cf9dc2d0c1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 2.2 LINUX 注册

* 运行注册

```
sudo gitlab-runner register
```

* 输入你的 GitLab URL

```
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )
https://xxx.xxx
```

* 输入 `注册令牌` 来注册 Runner

```
Please enter the gitlab-ci token for this runner
xxx
```

* 输入 Runner 说明

```
Please enter the gitlab-ci description for this runner
[hostame] my-runner
```

* 输入 Runner 的 tags

```
Please enter the gitlab-ci tags for this runner (comma separated):
my-tag,another-tag
```

* 输入 Runner 执行方式

```
Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
shell
```

* 如果是在 Docker 中运行, you'll be asked for the default image to be used for projects that do not define one in .gitlab-ci.yml:

```
Please enter the Docker image (eg. ruby:2.1):
alpine:latest
```

## 3 链接成功

### 3.1 runner 列表

![runner-setting](https://upload-images.jianshu.io/upload_images/13859457-bc049fd86e240035.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 3.2 runner 修改

![](https://upload-images.jianshu.io/upload_images/13859457-65efe242bf766b67.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 4 编写 `.gitlab-ci.yml` 集成

```
stages:
  - build
  - test

job 1:
  stage: build
  script: "echo $GOPATH"
  tags:
  - fujh_runner
  only:
  - master

job 2:
  stage: test
  script: "uname -a"
  tags:
  - fujh_runner
  only:
  - master
```

其中`tags`是表示你配置的`runner`的`tags`
`only`表示git中的分支

## 5 执行集成

* 下次提交代码就会走集成任务了

![](https://upload-images.jianshu.io/upload_images/13859457-671fad6cf2be8969.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 任务阶段

![](https://upload-images.jianshu.io/upload_images/13859457-544bfe059dff44f4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 详情

![](https://upload-images.jianshu.io/upload_images/13859457-e6297fd619727b14.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![](https://upload-images.jianshu.io/upload_images/13859457-e3511f9a3f4be935.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 参考

* [Install GitLab Runner manually on GNU/Linux](https://docs.gitlab.com/runner/install/linux-manually.html)
* [Registering Runners](https://docs.gitlab.com/runner/register/index.html)
* [Docker CE 镜像源站](https://yq.aliyun.com/articles/110806?spm=5176.8351553.0.0.151c19911eJVWX)
* [gitlab + gitlab-runner 集成 CICD](https://segmentfault.com/a/1190000016069906)





