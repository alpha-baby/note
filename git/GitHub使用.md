# GitHub使用
## GitHub创建远程仓库
新建仓库：**[github](https://github.com/new)**
如果没有github账号的可以去注册一个
![-w982](media/15356187529919/15356199351040.jpg)
创建远程仓库以后我们就把本地仓库推送到远程仓库中：![YW}{NY}[QU_]R`PWD}_R-47](media/15356187529919/YW%7D%7BNY%7D%5BQU_%5DR%60PWD%7D_R-47.png)

## 连接本地与远程仓库
把其中的两条git命令复制到gitbash中执行
其中在执行第二个命令的时候需要你输入你在github上的`username`和`password`
然后我们在另外新建一个本地仓库：(命令在我图中所示，我建立的仓库名为git2)
![](media/15356187529919/IZWQJW$G%60D%25JEW7VM3$H5CG.png)
然后我们再建立与远程仓库的链接
>$ git remote add origin https://github.com/mydarlingguan/gitlearn.git

然后把远程仓库中的文件拉取到本地仓库中(因为是开源的并不需要账号密码)
>$ git pull origin master

![](media/15356187529919/N1RF%25%25X6KVVA%60~%5DB5G1~WHW.png)
查看仓库中并有了a.txt
## 如何多人协作
我们页可以使用`$ git clone` 命令拉取远程仓库中的代码
首先我们还是新建一个目录 git3 进入目录 然后使用克隆命令，使用克隆命令就不需要我们使用`$ git init`命令初始化仓库，
![](media/15356187529919/EZKUVOM%7DBMRRLO%25UBUZ%7D%25%7DM.png)
然后后我们现在有有三个本地仓库与远程仓库建立的联系，都具有一样的代码，着三个人就可以同时进行开发
然后我们在git3中新建文件b.txt 然后写入'abc'，然后添加到本地仓库中，接着提交到本地仓库中，最后推到远程仓库中
![](media/15356187529919/-NSOXTP6QA-M_H_LRM4Q55S.png)
我们进入我们的github对应的仓库中就能发现我们新添加的b.txt
![](media/15356187529919/MN63NI~D2B9-@1HC@R$I--F.png)
然后我们回到git1的仓库中，然后我们可以看到里面并没有b.txt文件，然后需要我们另外再重新拉取远程仓库中的代码(需要运行的命令都在图片中展示了出来)
![](media/15356187529919/IFX6%7BJM%7D@D$M%7B2T7WSO%7B_%60E.png)
然后我们在git1中再修改a.txt(在a.txt最后追加'hello python')，然后保存并上传到远程服务器
![](media/15356187529919/D%5DPMA_E5E13U%7D947Y-$D~%25R.png)
成功后便可以在github中看到a.txt文件中增加了a.txt


## Git常用命令总结
### 本地仓库
git init ：创建本地仓库
git add ：将文件或者文件夹添加到本地仓库的暂存区
git commit ：将add的暂存区所有内容提交到本地仓库的指定分支
git status ：查看状态（文件和本地仓库的对应文件是否一致）
git log ：查看文件的日志信息
### 远程仓库
git push ：将本地仓库的内容推送到远程仓库
git pull ：将远程仓库的内容更新到本地仓库
git clone ：将远程仓库复制到指定目录并自动创建本地仓库于远程仓库关联
