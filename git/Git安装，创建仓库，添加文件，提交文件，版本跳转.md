# Git安装，创建仓库，添加文件，提交文件，版本跳转
Git是一款免费、开源的分布式版本控制系统，用于敏捷高效的处理任何或大或小的项目版本管理。
最原始的版本控制是纯手工的版本控制：修改文件，保存文件副本。有时候偷懒省事，保存副本时命名比较随意，时间长了就不知道哪个是新的，哪个是老的了。即使知道了新旧，可能也不知道每个版本的内容是什么了。相对上一版本做了什么修改，当几个版本过去后，很可能就是会变得特别的杂乱。
## Git的特点
分布式相比集中式的最大区别在于开发者可以以提交到本地，每个开发者通过克隆(git clone)；在本地机器上拷贝一个完整的git仓库.

直接记录快照，而非差异比较；Git更像是把变化的文件作快照后，记录在一个微型的文件系统中。
近乎所有的操作都是本地执行：在Git中的绝大多是操作都只需要访问本地文件和资源，不用连网。
时刻保持数据完整性；在保存到Git之前，所有数据都要进行内容的校验和(checksum)计算，并将结果作为数据的唯一标识和索引。
多数操作仅添加数据：常用的Git操作大仅仅是把数据添加到数据库。
#### Git的基本作用有如下两点
1：版本控制
2：多人协作开发
## Git的安装
### Linux的安装很简单
> $ sudo apt-get install git 

### windows:
首先到[官网下载](https://git-scm.com/downloads)Git的安装包
然后按照window常规软件的安装方法安装git
安装完成后，在开始菜单里找到“Git”-> “Git Bash”，蹦出一个类似命令行窗口的东西，就说明Git安装成功！
![](media/15354270105842/63Z%7DT8S9BD0K7JFYGJUI-L6.png)
安装完成后，还需要最后一步设置，在命令行输入：
```
$ git config --global user.name "Your Name"
$ git config --global user.email "email@example.com"
```
## Git的使用
### 创建版本仓库
首先进入桌面
`$ cd Desktop`
使用mkdir命令创建仓库
`$ mkdir git1`
进入仓库目录
`$ cd git1`
将该git目录编程Git可以管理的仓库
`$ git init`
创建文件并在文件中写入东西
`$ touch a.txt`
写入
`hello git`
### 提交文件到仓库
将一个需要提交到版本库的文件a.txt放到git1目录
首先这里再明确一下，所有的版本控制系统，其实只能跟踪文本文件的改动，比如TXT文件，网页，所有的程序代码等等，Git也不例外。版本控制系统可以告诉你每次的改动，比如在第5行加了一个单词“Linux”，在第8行删了一个单词“Windows”。而图片、视频这些二进制文件，虽然也能由版本控制系统管理，但没法跟踪文件的变化，只能把二进制文件每次改动串起来，也就是只知道图片从100KB改成了120KB，但到底改了啥，版本控制系统不知道，也没法知道。
使用 git add命令告诉Git，把文件添加到仓库
`$ git add a.txt`
(`$ git add .` 表示提交所有文件和文件夹)
![S1{}YAMIWW7V0$}TS{O4K](media/15354270105842/S1%7B%7DD%5DYAMIWW7V0$%7DTS%7BO4K.png)
使用git commit命令把文件提交到仓库
`$ git commit -m '新项目，刚刚添加了一个登陆功能'` # -m 后面输入的是本次提交的说明，可以输入任意内容，当然最好是有意义的，这样你就能从历史记录里方便地找到改动记录。
![-NPWQY_~I6OH_ODGYZ2](media/15354270105842/-NPWQY%7BY4%5D_~I6OH_ODGYZ2.png)

为什么Git添加文件需要add，commit一共两步呢？因为commit可以一次提交很多文件，所以你可以多次add不同的文件，比如：
```
$ git add file1.txt
$ git add file2.txt file3.txt
$ git commit -m "add 3 files."
```
我们已经成功地添加并提交了一个a.txt文件，现在，是时候继续工作了，于是，我们继续修改a.txt文件，在文件最后添加：
`hello world`
现在，运行git status命令看看结果
`$ git status`
![-`PP{RD$VZS_3L5T2~E-JJE](media/15354270105842/-%60PP%7BRD$VZS_3L5T2~E-JJE.png)
git status命令可以让我们时刻掌握仓库当前的状态，上面的命令输出告诉我们，readme.txt被修改过了，但还没有准备提交的修改.
使用git diff命令查看我们修改了文件具体哪点的内容
`$ git diff a.txt`
![G-FBB$OVW2EF16PS0-M9@-](media/15354270105842/G-FBB$OVW2EF16PS0-M9@-L.png)
git diff顾名思义就是查看difference，显示的格式正是Unix通用的diff格式，可以从上面的命令输出看到，我们在在后面添加了一行_hello world_。
知道了对a.txt作了什么修改后，再把它提交到仓库就放心多了，提交修改和提交新文件是一样的两步，第一步是git add：
`$ git add a.txt`
然后就可以使用git commit 命令提交了
`$ git commit -m 'add new row of hello world'`
![G-FBB$OVW216PS0-M9@-](media/15354270105842/%60581%5DQ8ST_@15NS3-3X%5B1EY.png)
像这样，你不断对文件进行修改，然后不断提交修改到版本库里，就好比玩RPG游戏时，每通过一关就会自动把游戏状态存盘，如果某一关没过去，你还可以选择读取前一关的状态。有些时候，在打Boss之前，你会手动存盘，以便万一打Boss失败了，可以从最近的地方重新开始。Git也是一样，每当你觉得文件修改到一定程度的时候，就可以“保存一个快照”，这个快照在Git中被称为commit。一旦你把文件改乱了，或者误删了文件，还可以从最近的一个commit恢复，然后继续工作，而不是把几个月的工作成果全部丢失。
当然了，在实际工作中，我们脑子里怎么可能记得一个几千行的文件每次都改了什么内容，不然要版本控制系统干什么。版本控制系统肯定有某个命令可以告诉我们历史记录，在Git中，我们用git log命令查看：
![Y-H[SSIH`A6W}J7$Q7TW{MT](media/15354270105842/Y-H%5BSSIH%60A6W%7DJ7$Q7TW%7BMT.png)
git log命令显示从最近到最远的提交日志，我们可以看到4次提交.
如果觉得显示得很乱则使用如下命令查看：
`$ git log --pretty=oneline`
![D$KPC63C_%WOK9Y@VNFB](media/15354270105842/D%7B$KP%60C63C_%25WOK9Y@V%7BNFB.png)
如何退回到上一个版本呢？使用git reset命令退回上一个版本就是HEAD^，上上一个版本就是HEAD^^，如果是上一百个版本就是HEAD~100，比如我们现在退回到前一个版本：
`$ git reset --hard HEAD^`
我们连续退回几个，知道初始的状态：
![D$KPC63C_%WO9Y@VNFB](media/15354270105842/XPY-DCC@63%7BE%5B@%7DCQG%5B34LI.png)
我们已经来到了第一个版本，但是我们如何回到最新的版本呢？
办法其实还是有的，只要上面的命令行窗口还没有被关掉，你就可以顺着往上找啊找啊，找到那个最新版本的commit id，重历史数据我们知道最新版本的commit id是4144c5，于是就可以指定回到未来的某个版本：
`$ git reset --hard 4144c5`
`然后再查看log信息`
![](media/15354270105842/V_%60%5BL7X3-BV%5BR7G5%7DE02%5BI9.png)
在，你回退到了某个版本，关掉了电脑，第二天早上就后悔了，想恢复到新版本怎么办？找不到新版本的commit id怎么办？

在Git中，总是有后悔药可以吃的。当你用`$ git reset --hard HEAD^`回退到以前的某个版本时，再想恢复到新的版本时，就必须找到append GPL的commit id。Git提供了一个命令git reflog用来记录你的每一次命令：
![](media/15354270105842/ZDA6SD$W%5B%7BP%7B%7D@@GS0O9QZX.png)

