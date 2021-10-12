# Mac强制更换壁纸

转载 [ZJ 进朱者赤](https://mp.weixin.qq.com/s?__biz=MzIwMjY2NDE0MQ==&amp;mid=2247483795&amp;idx=1&amp;sn=74298c2b9284df3d1b48470985bbb8c5&amp;chksm=96da7031a1adf92731362f2ba5581670f102dffbad87a41a7ab56c7e14e49ecbec90eafa7eb1&token=80976224&lang=zh_CN#wechat_redirect)

## 第一步

替换系统壁纸的资源（路径为：/资源库/Desktop Pictures/）



进入文件位置

1. 进入访达/Finder
2. 快捷键shift+command+G  ，输入：/资源库/Desktop Pictures/ 或者命令行 cd /Library/Desktop\ Pictures/ 然后打开

![10-12-zEoR4l](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/10-12-zEoR4l.jpg)

1.3 用自己的图片替换掉该该路径下图片，需要文件名+格式名完全一致

      名称为 ：Desktop201810.JPG 

## 第二步

进入终端工具并输入如下命令：

```bash
defaults write com.apple.dock desktop-picture-show-debug-text -bool TRUE;killall Dock
```

![10-12-y2vPsa](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2021/10-12-y2vPsa.jpg)

备注：此时壁纸中间是含图片描述的，不要慌，继续执行下面的命令即可。

```bash
defaults delete com.apple.dock desktop-picture-show-debug-text;killall Dock
```

图片
注意事项：

1. 命令的顺序有先后要求，请勿颠倒
2. 如果效果不一致，可以锁屏或者重启后再看，或者再执行一遍
3. 如果是16寸，壁纸图片尽可能选择2k以及以上的，效果最佳。
4. 可能会不定时失效，重新设置即可
