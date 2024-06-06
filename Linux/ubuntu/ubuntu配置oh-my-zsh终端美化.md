# ubuntu配置终端

首先给ubuntu配置一个国内速度比较快的源，例如[阿里源](https://developer.aliyun.com/mirror/ubuntu)和[清华源](https://mirror.tuna.tsinghua.edu.cn/help/ubuntu/),具体配置过程可以百度其他教程。

安装zsh：
```bash
sudo apt-get install zsh
```

修改ubuntu的默认shell为zsh：
```bash
chsh -s /bin/zsh
```

执行以上命令来更换可能会报错如下：chsh: PAM: Authentication failure，可以用如下方法来解决：
https://blog.csdn.net/LFTUUI/article/details/60148800

oh-my-zsh的官网为：`https://ohmyz.sh/`。安装Oh-my-zsh：
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

你可能出出现报错：`curl: (7) Failed to connect to raw.github.com port 443: Connection refused`, 这个原因就是因为你被墙了，让你终端翻墙出去就好了。

终端可以用这个命令来把数据代理出去：`export all_proxy="socks5://127.0.0.1:10808"`

# 配置中文 man 手册

## 安装 man 命令工具

```bash
sudo apt update
sudo apt install man-db manpages-posix
sudo apt install manpages-dev manpages-posix-dev
```

```
1.安装中文man手册
sudo apt-get install manpages-zh

2.查看中文man手册安装路径
dpkg -L manpages-zh | less

可见中文man手册是安装在路径/usr/share/man/zh_CN/下

3.给中文man设置一个命令
为了和系统原来的man区分开，用alias给中文man的命令设置一个别名

alias cman='man -M /usr/share/man/zh_CN'

为永久生效，可把上面的命令写进启动文件中

如：修改 ~/.bashrc ，添加上面的命令

我修改的是 /etc/bash.bashrc

4.重启终端
命令：cman可以查看中文man手册，而man可以查看原man手册（英文）
```

# 安装字体

[nerd fonts](https://www.nerdfonts.com/)

到官网上下载 [Ubuntu Nerd Font](https://www.nerdfonts.com/font-downloads)

安装需要的命令 https://blog.csdn.net/soulmate_P/article/details/87856420

sudo mkdir -p /usr/share/fonts/custom
sudo mv [your ttf file] /usr/share/fonts/custom
sudo chmod 744 /usr/share/fonts/custom/[your ttf file]

sudo mkfontscale  #生成核心字体信息
sudo mkfontdir
sudo fc-cache -fv

# 安装oh-my-zsh主题

powerlevel10k github 地址为： https://github.com/romkatv/powerlevel10k

可以直接使用下列命令安装：

```bash
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

把一下配置 ZSH_THEME="powerlevel10k/powerlevel10k" in ~/.zshrc.

然后`$ source ~/.zshrc`

然后可以执行一下命令配置想要的效果，`$ p10k configur`

# 安装 neofetch

```bash
sudo add-apt-repository ppa:dawidd0811/neofetch
sudo apt-get update
sudo apt-get install neofetch
```

在apt install 的可能出现一下错误：
```bash
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

可以参考这篇文章的第三种方法。

# 安装oh-my-zsh插件

## 安装 zsh-syntax-highlighting

安装方法如下（oh-my-zsh 插件管理的方式安装）：  
1.Clone项目到`$ZSH_CUSTOM/plugins`文件夹下 (默认为 `~/.oh-my-zsh/custom/plugins`)

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

2.在 **Oh My Zsh** 的配置文件 (`~/.zshrc`)中设置:

    plugins=(其他插件 zsh-syntax-highlighting)

3.运行 `source ~/.zshrc` 更新配置后重启**item2**:

* * *

## zsh-autosuggestions(命令自动补全)

[**zsh-autosuggestions**](https://github.com/zsh-users/zsh-autosuggestions)，如图输入命令时，会给出建议的命令（灰色部分）按键盘 → 补全  
![clipboard.png](https://segmentfault.com/img/bVbn4YS?w=394&h=42))

如果感觉 → 补全不方便，还可以自定义补全的快捷键，比如我设置的逗号补全，只需要在 `.zshrc` 文件添加这句话即可

    bindkey ',' autosuggest-accept

官网中有多种[安装方式](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md)，这里选择oh my zsh中的安装方式：

1.Clone项目到`$ZSH_CUSTOM/plugins`文件夹下 (默认为 `~/.oh-my-zsh/custom/plugins`)

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

2.在 **Oh My Zsh** 的配置文件 (`~/.zshrc`)中设置:

    plugins=(其他插件 zsh-autosuggestions)

3.运行 `source ~/.zshrc` 更新配置后重启**item2**。

> 当你重新打开终端的时候可能看不到变化，可能你的字体颜色太淡了，我们把其改亮一些：

    cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    vim zsh-autosuggestions.zsh
    # 修改 ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10' 

> 修改成功后需要运行 `source ~/.zshrc` 更新配置，然后开发新的**item2**窗口即可看到效果。

* * *

## git

默认已开启,可以使用各种git命令的缩写，比如：

    git add --all ===> gaa
    
    git commit -m ===> gcmsg

查看所有 `git` 命令缩写

    cat ~/.oh-my-zsh/plugins/git/git.plugin.zsh

或者查询[git快捷对照表](https://www.jianshu.com/p/7aa68e5a88f3)。

## git-open


在终端里打开当前项目的远程仓库地址

不要小看这个插件欧，每次改完本地代码，当你想用浏览器访问远程仓库的时候，就知道这个插件多方便了 😘

支持打开的远程仓库

- github.com
- gist.github.com
- gitlab.com
- 自定义域名的 GitLab
- bitbucket.org
- Atlassian Bitbucket Server (formerly Atlassian Stash)
- Visual Studio Team Services
- Team Foundation Server (on-premises)

**安装**

克隆项目
```
git clone https://github.com/paulirish/git-open.git $ZSH_CUSTOM/plugins/git-open
```

在`~/.zshrc`中配置

```
plugins=(其他的插件 git-open)
```

使配置生效
```
source ~/.zshrc
```

