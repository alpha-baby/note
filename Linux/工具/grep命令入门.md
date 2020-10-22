# grep 命令入门

**grep** 全称（Global Regular Expression Print），它是linux中非常常用的命令，在工作和学习中也可以大大提升我们的效率，我们学习它的基本用法是非常有必要的。

## 常用

```bash
# 搜索/home/sqlsec/Desktop/BBS/中的所有php后缀中的password关键词
grep -r "password" --include="*.php"  /home/sqlsec/Desktop/BBS/

# 可以添加多个后缀
grep -r "关键词" --include="*.后缀1"  --include="*.后缀2" 目标路径

# 搜索/home/sqlsec/Desktop/BBS/中的所有php后缀中的password关键词
# 不搜索js后缀
grep -r "password" --include="*.php" --exclude="*.js"  /home/sqlsec/Desktop/BBS/
```

## 入门第一条命令

```zsh
$ ps aux | grep system
# 结果
ps aux | grep system
root       374  0.0  0.1  29632  2604 ?        Ss    2018  92:37 /lib/systemd/systemd-journald
root       424  0.0  0.1  44768  3196 ?        Ss    2018   0:26 /lib/systemd/systemd-udevd
root      1043  0.0  0.1  29384  3536 ?        Ss    2018   0:28 /lib/systemd/systemd-logind
message+  1050  0.0  0.1  43008  2692 ?        Ss    2018   0:05 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation
root      1487  0.0  0.1  36784  3188 ?        Ss    2018   0:00 /lib/systemd/systemd --user
root     23475  0.0  0.0  13232   904 pts/2    S+   16:20   0:00 grep system
```

**解释：**
首先，`ps aux`命令是列出linux中运行的所有进程，你可以自己去尝试下这个命令，一般这个命令会输出非常多的进程，但是我这是只想要找和`system`相关的命令。所以我在命令后加上这个：`| grep system`。这个命令的意思是匹配或者说查找和`"system"`这个字符串相关的内容，`grep`命令默认是针对行进行匹配，如果在某一个行匹配到了想要的内容，那么久输出这一行的数据。

可以注意到grep默认是不显示颜色的，如果想要显示颜色，会有一个`--color=auto`的参数。

![](https://tva1.sinaimg.cn/large/006tNbRwly1gasq4fot7bj314806swpn.jpg)

我们可以使用`grep --help` 或者 `man grep`参看更多的参数。

## 常用的参数

首先我在目录：`/tmp/practice/` 下有这样一个文本文件：

```zsh
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd
# 结果
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:root:/usr/games:/usr/sbin/root
root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

配合cat命令可以查找文件中存在`"root"`字符串的行：

```zsh
$ cat /tmp/practice/passwd | grep --color=auto root
# 结果
root:x:0:0:root:/root:/bin/bash
games:x:5:60:root:/usr/games:/usr/sbin/root
root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

### `-v` 取反

`-v`参数是取反的意思，比如我们使用命令：

```zsh
$ cat /tmp/practice/passwd | grep --color=auto -v root
# 结果
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
```

加上了`-v`参数就是找出没有匹配到的行数。

### `-i` 忽略大小写

比如我们使用命令：

```zsh
$ cat /tmp/practice/passwd | grep ROot
# 结果为空
$ cat /tmp/practice/passwd | grep -i --color=auto ROot
# 结果
root:x:0:0:root:/root:/bin/bash
games:x:5:60:root:/usr/games:/usr/sbin/root
root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

如果我们加上了`-i`参数，**grep**命令在匹配字符串的时候就会忽略大小写。

### `-n` 显示行号

比如我们想要知道文件中出现`"root"`字符串的行都是在多少行：

```zsh
$ cat /tmp/practice/passwd | grep --color=auto -n root
# 结果
1:root:x:0:0:root:/root:/bin/bash
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

这时候如果我们想要修改某一行的数据直接使用命令：`$ vim +[n] [file]`。 `n`表示行数，`file`表示文件路径。
比如我想去修改`/tmp/practice/passwd`文件的第七行：

```zsh
$ vim +7 /tmp/practice/passwd
```

### `-c` 显示匹配到了多少行

比如我想知道文件中有多少行中包含了`"root"`参数。

```zsh
$ cat /tmp/practice/passwd | grep --color=auto -c root
# 结果
3
```

我们就可以知道在文件`/tmp/practice/passwd`中有三行包含了`"root"`字符串。

### `-o` 仅显示匹配到的字符串

在前面我们使用命令：`$ cat /tmp/practice/passwd | grep root`会显示一行的所有内容。

```zsh
$ grep --color=auto -o -n root
# 结果
1:root
1:root
1:root
6:root
6:root
7:root
```

`-o`参数仅仅只会显示匹配到的内容。

### `-An`显示匹配到的后n行 `-Bn`显示匹配到的前n行

```zsh
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd | grep --color=auto -A2 -n root
1:root:x:0:0:root:/root:/bin/bash
2-daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
3-bin:x:2:2:bin:/bin:/usr/sbin/nologin
--
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd | grep --color=auto -A1 -n root
1:root:x:0:0:root:/root:/bin/bash
2-daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
--
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd | grep --color=auto -A3 -n root
1:root:x:0:0:root:/root:/bin/bash
2-daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
3-bin:x:2:2:bin:/bin:/usr/sbin/nologin
4-sys:x:3:3:sys:/dev:/usr/sbin/nologin
--
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd | grep --color=auto -B3 -n root
1:root:x:0:0:root:/root:/bin/bash
--
3-bin:x:2:2:bin:/bin:/usr/sbin/nologin
4-sys:x:3:3:sys:/dev:/usr/sbin/nologin
5-sync:x:4:65534:sync:/bin:/bin/sync
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
root@VM-0-4-ubuntu:/tmp/practice# cat /tmp/practice/passwd | grep --color=auto -B2 -n root
1:root:x:0:0:root:/root:/bin/bash
--
4-sys:x:3:3:sys:/dev:/usr/sbin/nologin
5-sync:x:4:65534:sync:/bin:/bin/sync
6:games:x:5:60:root:/usr/games:/usr/sbin/root
7:root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

从上面的练习中我们就可以认识到 `-An` 和 `-Bn`参数的作用，`A`就是`after`, `B`就是`before`.

### `-e` 实现or逻辑

找出文件中既包含`root`也包含`bash`的行。

```zsh
$ cat /tmp/practice/passwd | grep -e bash --color=auto
root:x:0:0:root:/root:/bin/bash
$ cat /tmp/practice/passwd | grep -e root -e bash --color=auto
root:x:0:0:root:/root:/bin/bash
games:x:5:60:root:/usr/games:/usr/sbin/root
root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

从这里我们就知道`-e`参数的作用了。


### `-w` 匹配整个单词

我想查找文件中出现`"bin"`字符串的行。

```zsh
$ cat /tmp/practice/passwd | grep -e "bin" --color=auto
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:root:/usr/games:/usr/sbin/root
root:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```

我们可以看到以上命令会匹配到`"sbin"`这个字符串，这时候我们就可以使用`-w`这个参数来限定查找某个词。

```zsh
$ cat /tmp/practice/passwd | grep -we "bin" --color=auto
root:x:0:0:root:/root:/bin/bash
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
```

