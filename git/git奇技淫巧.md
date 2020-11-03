# 通过git拉取github/gitlab上的Pull Request(PR)/Merge Request(MR)到本地进行code review

## github

```bash
git fetch {remote repo} pull/{pr id}/head:{new local branch}
```

例如：

```bash
git fetch origin pull/3188/head:pr3188
```

>注意
>3188是PR的id

## gitlab

>参考
>https://segmentfault.com/a/1190000018733141?utm_medium=referral&utm_source=tuicool

首先你要知道你想code review 的pr的id，使用命令：

```bash
git ls-remote {remote repo} | grep {pr id}
# 例如：
git ls-remote origin | grep 1000
```

输出：

```txt
......
5d30d7841389901ce810e327ea71ee2b3a2d5ab1        refs/merge-requests/1000/head
......
```

```bash
git pull {remote repo} refs/merge-requests/{pr id}/head
# 例如：
git pull remote refs/merge-requests/1000/head
```