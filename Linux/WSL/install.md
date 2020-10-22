# 拉取 dotfiles 配置文件

```bash
git clone https://github.com/alpha-baby/dotfiles
```

# 配置国内源

## 阿里源

参考网站

https://developer.aliyun.com/mirror/ubuntu?spm=a2c6h.13651102.0.0.3e221b11lNtrTf

## 配置git 

配置不能显示中文路径或文件

```bash
sudo apt install git
git config --global core.quotepath false
```

# homebrew 安装

可以参考
https://linuxtoy.org/archives/linuxbrew.html

```bash
sudo apt-get install build-essential
sudo apt-get install linuxbrew-wrapper
```

```bash
# 检查 brew
brwe help
```

后面还需要配置brew 的环境变量

# 远程开发配置（ssh配置）

## 安装 ssh 服务

```bash
sudo apt-get update
sudo apt-get install openssh-client openssh-server openssh-sftp-server
sudo service ssh restart
```

## 配置 ssh 服务

```
PermitRootLogin yes #允许root登录
PermitEmptyPasswords no #不允许空密码登录
PasswordAuthentication yes # 设置是否使用口令验证。
```

## jetbrains 连接ssh 乱码

> 参考
> https://aber.sh/articles/WSL-locale-lang/

使用如下命令修改Ubuntu子系统的LANG

```bash
sudo vim /etc/default/locale
# 之前的LANG为：

LANG=C.UTF-8
# 改为：

LANG=zh_CN.UTF-8
#然后安装对应的语言包

sudo apt-get install language-pack-zh-hans
#最后关掉当前的子系统窗口重开即可。
```

# WSL root 密码修改

[wsl忘记root密码](https://blog.csdn.net/qq_41961459/article/details/105128326)

```cmd
ubuntu1804.exe config --default-user root
ubuntu1804.exe config --default-user 你的用户名
```
# 安装zsh

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

```bash
sudo apt install zsh
chsh -s /bin/zsh # 不要用sudo 如果没有成功 可以到 /etc/passwd直接修改
```

## 安装 oh-my-zsh

[oh-my-zsh官网](http://ohmyz.sh/)

```bash
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

## 安装 oh-my-zsh插件管理工具 Zinit

一键安装 Zinit

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
```

## 安装字体

https://www.nerdfonts.com/font-downloads

到以上网站中下载一款字体，我自己用的是 Hack Nerd Font

## 安装powerlevel10k主题

```bash
brew install romkatv/powerlevel10k/powerlevel10k
echo 'source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme' >>! ~/.zshrc
```
OR
```bash
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```
Set `ZSH_THEME="powerlevel10k/powerlevel10k"` in `~/.zshrc`





