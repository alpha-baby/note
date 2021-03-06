# vim 使用笔记

# vim tab 切换

vim 中可以使用vim命令来切换tab，

```
:tabnew [++opt选项] ［＋cmd］ 文件            建立对指定文件新的tab
:tabc       关闭当前的tab
:tabo       关闭所有其他的tab
:tabs       查看所有打开的tab
:tabp      前一个
:tabn      后一个
标准模式下：
gt , gT 可以直接在tab之间切换。
更多可以查看帮助 :help table ， help -p
```

一般自己都配置了自己喜欢的快捷键来切换tab

```
" 快速调整tab 切换
map tu :tabe<CR>
map tl :+tabnext<CR>
map tj :-tabnext<CR>
```

# nerdtree 快捷键使用

快捷键使用

* `C`: 使用当前目录作为父目录
* `u`: 当前父目录的父目录作为根目录,但是光标跳转到父目录的父目录上
* `U`:  当前父目录的父目录作为根目录,但是光标的位置停留在当前位置
* `o`: 打开一个目录或者文件,创建的是buffer,也可以用来打开书签
* `?`: 打开帮助文档
* `go`: 打开一个文件但是光标仍然留在NERDTree中,创建的是Buffer
* `t`: 打开一个文件,创建的是Tab,对书签同样生效
* `T`: 打开一个文件,但是光标仍然留在NERDTree中,创建的是Tab,对书签同样生效
* `gi`: 水平分割创建文件的窗口，但是光标仍然留在NERDTree
* `s`: 垂直分割创建文件的窗口，创建的是buffer
* `gs`: 和gi，go类似
* `x`: 收起当前打开的目录
* `X`: 收起所有打开的目录
* `e`: 以文件管理的方式打开选中的目录
* `D`: 删除书签
* `P`: 大写，跳转到当前根路径
* `p`: 小写，跳转到光标所在的上一级路径
* `K`: 跳转到第一个子路径
* `J`: 跳转到最后一个子路径
* `和`: 在同级目录和文件间移动，忽略子目录和子文件
* `C`: 将根路径设置为光标所在的目录
* `u`: 设置上级目录为根路径
* `U`: 设置上级目录为跟路径，但是维持原来目录打开的状态
* `r`: 刷新光标所在的目录
* `R`: 刷新当前根路径
* `I`: 显示或者不显示隐藏文件
* `f`: 打开和关闭文件过滤器
* `q`: 关闭NERDTree
* `A`: 全屏显示NERDTree，或者关闭全屏





