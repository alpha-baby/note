# 小白入坑同性交友网站github总结

##常用词汇及含义

**1. watch** 表示会持续收到该项目的动态
**2. fork** 复制某个项目到自己的github仓库
**3. star** 可以理解为点赞的个数
**4. clone** 将远程服务器上的源代码下载到本地
**5. follow** 关注你感兴趣的作者，会收到他们的动态

![](https://test.demo-1s.com/images/2019/07/05/04l4e76cEvClFNMg.jpg)

可以从图中看到我们可以在途中一次找到上面的几个功能的区域，但是没有`follow`，如果想要关注某个开发者可以直接点击他的头像进去他的主页在头像下方就可以`follow`某个开发者

## in 关键字限制搜索范围 

我们可以使用一些搜索的技巧，就像我们使用搜索引擎一样，比如有个叫`google hack`的东西，很多学习安全的人都回去学google一些高级的搜索语法。在github中也同样有一些高级的搜索的语法。

xxx关键词 in:name 或者 description 或 readme

1. xxx in:name 项目名包含xxx的
2. xxx in:description 项目描述包含xxx的
3. xxx in:readme 项目的readme文件中包含xxx的

这上面的三种搜索技巧可以，组合使用。
下面我们可以试一试：(搜索项目名和readme文件中都有wechat的项目)

![](https://test.demo-1s.com/images/2019/07/05/PIhiVlWclb3IcmJ7.jpg)

## stars或fork数量关键词查找

`stars`和`fork` 通配符 `>` 或者 `>=` 或者 `<` `<=`
范围搜索：例如搜索stars在100到1000之间的项目 就是 `starts:100..1000`

例如我们查找`star`数量大于2000的golang的项目：

![](https://test.demo-1s.com/images/2019/07/05/m5LYX9eL6vDO7A3B.jpg)


 查找`fork`数量大于3000的Go教程项目：
 
 ![](media/15550789777426/15550836606288.jpg)

查找`fork`数量大于1000并且`stars`数量在1000到5000之间的项目：

![](https://test.demo-1s.com/images/2019/07/05/7t6NUS9yRn46W9ga.jpg)

## awesome 加强搜索

使用`awesome`可以在github中收集学习，工具，书籍类的相关项目
awesome 加关键字

例如我们来收你MongoDB相关的学习资料：

![](https://test.demo-1s.com/images/2019/07/05/rOks3QLueIEhI45T.jpg)

## 高亮代码

有很多时候可能我们会和别人讨论某个目录中某个文件中的某几行代码，这时候我们就可以把某几行代码标记为高亮，然后把对应的url链接发给别人，对方打开链接后就可以看到我们标记的高亮的代码了。

![](https://test.demo-1s.com/images/2019/07/05/0pG9KVTQfHjBCvyF.jpg)

我们首先可以鼠标左击行号就会选中这一行代码，接着到后面的行按住`shift`+`鼠标左击`就可以选中多行代码了，可以看到浏览器中的地址栏中的url链接，后面多出来了`#L26-L32`这样就可以标记高亮某几行代码了。

## 项目内搜索

当我们进入到某个开发者开源的仓库后，我们就可以使用很多github自带的很多的快捷键功能。

比如我们最常用的`t`:搜索源

[源代码浏览](#)

| 键盘快捷键 | 描述 |
| --- | --- |
| t | 激活文件查找器 |
| l | 跳转到代码中的一行 |
| w | 切换到新分支或标记 |
| y | 将URL展开为其规范形式。|
| i | 显示或隐藏差异的评论。  |
| b | 公开指责观点。 |

如果还想了解更多的快捷键，可以看github的官方文档，[快捷键](https://help.github.com/en/articles/using-keyboard-shortcuts)

## 搜索某个地区内的大佬

我们可以使用 `location:地点`，`language:语言` 来搜索大佬们，然后就可以和他们交换联系方式，同性交友就开始了。

比如我们试试，搜索重庆地区的golang大佬:

![](https://test.demo-1s.com/images/2019/07/05/PvvHZCanX591ZuvV.jpg)

## github cdn 加速

国内下载 GitHub 速度基本都是以几个 kb 为单位，不忍直视，如果下载内容都是代码，有很多办法可以解决，比如通过码云中转啊、直接通过 CDN 下载啊，什么？你不知道可以通过 CDN 下载？好吧没关系，现在我告诉你了：https://cdn.con.sh/。
但是上面的 CDN 并不能下载 release 里的内容，要想下载 release 里的内容，可以使用这个网站：https://toolwa.com/github/。打开网站，输入 release 里面的文件下载链接，点击起飞即可加速下载。

# 总结

如果你学会了这些简单的github骚操作，基本上就可以玩转github了。