# Ubuntu16.04+python3+django1.11+uWSGI+nginx部署django项目

相信很多的小伙伴都和我遇到过同样的问题，我们学习django后写好项目后把代码放到服务器上肯定不能使用django自带的服务器给用户来使用我们的网站呀，因为django自带的服务器性能有限所以我们在真正部署的时候是不用它的，那怎么办呢？不用担心我教大家使用nginx服务器来解决这个问题。

## nginx

nginx是什么东西，就是和Apache，Tomcat类似的一款服务器软件，如果你真的不知道这是什么鬼东西那就真的没得必要往下面看了，建议先去弄弄清楚这个软件是什么东西，再回过来看就行了。上百度，谷歌搜一搜就好了，其实很简单的。

## uWSGI

其实着也是一个服务器软件啦，下面我提供了一个大佬写的文章快去学习学习了。
[https://blog.csdn.net/mnszmlcd/article/details/78819237](https://blog.csdn.net/mnszmlcd/article/details/78819237)

## 搭建的原理示意图

![-w728](media/15353568140630/15353581782220.jpg)

我们的目的肯定是是打通浏览器访问我们django代码的通道，首先着条通道上我们要修建两座桥梁，首先是nginx，这是提供给我们浏览器访问的入口，通过nginx转发80端口进来的数据包到本地环回地址(127.0.0.1)的8010端口上（其他端口也是阔以的，这里只是拿8010举例子），然后我们通过uWSGI开启本地的8010供本地访问，这里不理解我可以举个例子，在这里相当于我们运行了 

>$ python manage.py runserver 127.0.0.1:8010

nginx则起到了一个转发端口的功能，说完了原理，接下来就正式开始我们的安装过程了

## 配置

### 安装nginx

首先进入/etc/apt目录下

>$ cd /etc/apt

![-w318](media/15353568140630/15353606028659.jpg)
下载公钥
>$ wget http://nginx.org/keys/nginx_signing.key

(如果提示找不到命令wget，那就使用命令下载这个http工具：$ sudo apt-get install wget)
![-w720](media/15353568140630/15353606950245.jpg)
加载公钥
>$ sudo apt-key add nginx_signing.key

![-w529](media/15353568140630/15353607263227.jpg)
然后把下载源添加在apt下载源的后面 如果你不会使用vim编辑器，也可以使用nano这个比较简单一些
>$ sudo vim /etc/apt/sources.list 

![-w435](media/15353568140630/15353605047731.jpg)
因为我使用的ubuntu系统是16.04版本的对应的发行版名称是xenial
* Version 	codename 	Supported  Platforms
* 14.04 	   trusty 	    x86_64, i386, aarch64/arm64
* 16.04 	   xenial 	    x86_64, i386, ppc64el, aarch64/arm64
* 17.10 	   artful 	    x86_64, i386
* 18.04 	   bionic 	    x86_64
对应自己系统的版本选择对应的系统名
配置好源以后就开始下载安装了安装

>$ apt-get update
>$ apt-get install nginx
安装完成后我们就启动它
>$ nginx
执行命令后没有任何回显 使用ps命令可以查看进程是否启动
>$ ps aux | grep nginx

![-w664](media/15353568140630/15353614263275.jpg)

nginx启动后然后在浏览器中输入你服务器的ip地址，回车，只要不出下如下这样无法链接到服务器，说明你nginx是安装成功的
![-w439](media/15353568140630/15353621259586.jpg)
### 安装 uWSGI
uWSGI是python的一个第三方包，首先我们选择用python的虚拟环境来运行我们的项目
但是ubuntu16.04默认的是python3.5，首先我们需要更换为python3.6
加装含有python3.6.4的PPA
>$ sudo add-apt-repository ppa:deadsnakes/ppa

![-w529](media/15353568140630/15353625228494.jpg)
如果和我一样报错就可以运行如下命令，没有报错就可以不管了
>$ sudo apt install software-properties-common

重新运行如下命令，如果你是root用户则不用加上sudo，否则会出错
>$ add-apt-repository ppa:deadsnakes/ppa

![-w495](media/15353568140630/15353632535367.jpg)
>$ sudo apt-get update
>$ sudo apt-get install python3.

到了这里，因为源的问题，可能有点慢，，，，
![-w519](media/15353568140630/15353638480887.jpg)
查看新安装的python版本
>$ python3.6 -V

![-w326](media/15353568140630/15353637158858.jpg)
我们使用python3命令会默认的访问python3.5的版本，接下来我们替换掉原先的软连接
列出系统当前存在的python版本及python默认的版本
>$ ls -l /usr/bin | grep python
 
![-w761](media/15353568140630/15353640441360.jpg)
我们就是要替换掉途中的这个软连接
>$ sudo rm /usr/bin/python3
>$ sudo ln -s /usr/bin/python3.6 /usr/bin/python3

重新查看文件，发现多了图中的软连接，就说明成功了
![-w752](media/15353568140630/15353644087685.jpg)
 然后我们再运行python3 就默认进入3.6
 >$ python3
 
 ![-w496](media/15353568140630/15353644765470.jpg)
接着安装python虚拟环境
首先安装python3的pip下载工具
>$ sudo apt-get install python3-pip
>$ python3 -m pip -V

![-w414](media/15353568140630/15353706195434.jpg)
>$ python3 -m pip install virtualenv

如果你在运行这天命令的时候出现了如下报错，
![-w476](media/15353568140630/15353715891270.jpg)
则在~/.bashrc 文件末尾加上
`export PIP_REQUIRE_VIRTUALENV=false`
>$ source ~/.bashrc
>$ python3 -m pip install virtualenvwrapper

![-w772](media/15353568140630/15353717269971.jpg)
这样便安装成功
并把：
`
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source /usr/local/bin/virtualenvwrapper.sh
`
添加在~/.bashrc文件末尾
然后重新读取配置文件使得配置生效
![-w359](media/15353568140630/15353721237813.jpg)
>$ source ~/.bashrc
![-w585](media/15353568140630/15353722370563.jpg)
新建

>$ mkvirtualenv py3.6

![-w651](media/15353568140630/15353723388017.jpg)
进入虚拟环境py3.5 前面出下(py3.6)表示已经进入虚拟环境 并安装django，uwsgi
>$ workon py3.6

![-w364](media/15353568140630/15353724705313.jpg)
>$ pip install django==1.11

>$ pip install uwsgi

如果安装uwsgi出现了如下错误
![-w772](media/15353568140630/15353734025045.jpg)
则安装依赖如下
>$ sudo apt-get install libpython3.6-dev

然后重新安装uwsgi
>$ pip install uwsgi

![-w769](media/15353568140630/15353735047663.jpg)
知道这里我们就把需要的东西的下载安装好了
## django hello world
接下来我们使用django写一个简单的helloworld
![-w740](media/15353568140630/15353743253579.jpg)
上传项目到服务器中, 如果不知道怎么上传可以试试pycharm的这个功能
![-w627](media/15353568140630/15353751412115.jpg)
并上传到/var/www目录中
![-w508](media/15353568140630/15353755577476.jpg)
## 配置nginx，uWSGI
配置文件  django.conf 并放到目录 /etc/nginx/conf.d/ 中
![](media/15353568140630/K%5DR6A%60YK%7B65%255BNW%60R@AC0L.png)
![-w488](media/15353568140630/15353772680251.jpg)
然后配置文件 uwsgi.ini 并放到/var/www/hello中
![](media/15353568140630/H%7DQ%25LZ3E%5DD%5BCJ-6-%7BRTD9LM.png)

![](media/15353568140630/15353777452981.jpg)

然后运行uwsgi
>$ uwsgi --ini /var/www/hello/uwsgi.ini
>
>$ nginx -s stop
>
>$ nginx

然后便配置成功，可以访问了
![-w434](media/15353568140630/15353779769097.jpg)

你在以后修改了django文件保存后应该重启`uwsgi`
>$ uwsgi --reload uwsgi.pid

`uwsgi.pid`文件是你在运行`uwsgi --ini /var/www/hello/uwsgi.ini`后在`uwsgi.ini`同级目录下生成的文件。
