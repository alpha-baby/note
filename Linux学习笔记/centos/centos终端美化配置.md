# centos7.8

## 更换机器的软件源为国内源

### 更换阿里源

1. 进入yum文件夹

```bash
cd /etc/yum.repos.d/
```

2. 备份系统原来的repo文件

```bash
mv CentOS-Base.repo CentOS-Base.repo.bak  #此时已经不存在CentOS-Base.repo
```

3. 下载阿里云源

阿里源centos软件镜像地址为：https://developer.aliyun.com/mirror/centos?spm=a2c6h.13651102.0.0.3e221b11uBazPq

```bash
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

4. 执行yum源的更新命令

```bash
yum clean all && yum makecache # 重新生成新的缓存
# yum update #更新所有软件，你可以选择不执行
```

**如果你系统和我一样可以直接复制脚本**：（如果你不是root用户则需要自行加上 sudo）

```bash
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.bak
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all && yum makecache
```

## 安装zsh

首先检查下你的系统是否自带了**zsh**：

```bash
[root@VM-0-7-centos ~]# cat /etc/shells
/bin/sh
/bin/bash
/usr/bin/sh
/usr/bin/bash
/bin/tcsh
/bin/csh
```

使用yum工具安装**zsh**：

```bash
yum -y install zsh
```

切换系统默认shell为zsh：

```bash
chsh -s /bin/zsh
```

然后重启系统或者，注销用户重新登录，然后系统默认的shell就切换过来了：

```bash
echo $SHELL # 查看当前终端的默认shell
```

## 安装oh-my-zsh

安装git工具：

```bash
yum -y install git
```

安装oh-my-zsh：

```bash
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
```

如果显示如下界面表示成功：

```bash
         __                                     __   
  ____  / /_     ____ ___  __  __   ____  _____/ /_  
 / __ \/ __ \   / __ `__ \/ / / /  /_  / / ___/ __ \ 
/ /_/ / / / /  / / / / / / /_/ /    / /_(__  ) / / / 
\____/_/ /_/  /_/ /_/ /_/\__, /    /___/____/_/ /_/  
                        /____/                       ....is now installed!
Please look over the ~/.zshrc file to select plugins, themes, and options.

p.s. Follow us at https://twitter.com/ohmyzsh.

p.p.s. Get stickers and t-shirts at http://shop.planetargon.com.
————————————————
```

## 安装 oh-my-zsh插件管理工具 Zinit

一键安装 Zinit

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
```

## 安装字体

https://www.nerdfonts.com/font-downloads

到以上网站中下载一款字体，我自己用的是 Hack Nerd Font


## 配置git 

配置不能显示中文路径或文件

```bash
git config --global core.quotepath false
```

> 参考
> [加速你的 zsh —— 最强 zsh 插件管理器 zplugin/zinit 教程](https://www.aloxaf.com/2019/11/zplugin_tutorial/)
> [Powerlevel10k:Instant Prompt模式](http://londbell.github.io/2020/03/01/zsh-p10k-instant-prompt/)