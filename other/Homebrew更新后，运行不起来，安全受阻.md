# Homebrew 更新后，运行不起来，安全受阻

```yaml
HOMEBREW_VERSION: 4.3.3
ORIGIN: https://github.com/Homebrew/brew
HEAD: e130e47f23b8b806096f9ec4f2c193213b8ec908
Last commit: 32 hours ago
Core tap JSON: 04 Jun 03:40 UTC
Core cask tap JSON: 04 Jun 03:40 UTC
HOMEBREW_PREFIX: /opt/homebrew
HOMEBREW_API_DOMAIN: https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api
HOMEBREW_BOTTLE_DOMAIN: https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
HOMEBREW_BREW_GIT_REMOTE: https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
HOMEBREW_CASK_OPTS: []
HOMEBREW_CORE_GIT_REMOTE: https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
HOMEBREW_MAKE_JOBS: 10
Homebrew Ruby: 3.3.2 => /opt/homebrew/Library/Homebrew/vendor/portable-ruby/3.3.2/bin/ruby
CPU: 10-core 64-bit arm_firestorm_icestorm
Clang: 14.0.3 build 1403
Git: 2.43.0 => /opt/homebrew/bin/git
Curl: 7.86.0 => /usr/bin/curl
macOS: 13.2.1-arm64
CLT: 14.3.1.0.1.1683849156
Xcode: N/A
Rosetta 2: false
```
<a name="VcJyC"></a>
## 现象
在执行 brew 命令的时候，brew 会自动更新自己的版本，也就是相当于 brew 默认是打开了自己的自动更新：
```yaml
==> Downloading https://ghcr.io/v2/homebrew/portable-ruby/portable-ruby/blobs/sha256:bbb73a9d86fa37128c54c74b020096a646c46c525fd5eb0c4a2467551fb2d377
Already downloaded: /Users/fujianhao/Library/Caches/Homebrew/portable-ruby-3.3.2.arm64_big_sur.bottle.tar.gz
==> Pouring portable-ruby-3.3.2.arm64_big_sur.bottle.tar.gz
/opt/homebrew/Library/Homebrew/cmd/vendor-install.sh: line 218: 86692 Killed: 9               "./${VENDOR_VERSION}/bin/${VENDOR_NAME}" --version > /dev/null
Error: Failed to install ruby 3.3.2!
Error: Failed to upgrade Homebrew Portable Ruby!
```
然后执行随便在执行任何
<a name="dPpXv"></a>
### 报错原因是：
/opt/homebrew/Library/Homebrew/cmd/vendor-install.sh
如上脚本会在运行 brew 的时候去下载和安装需要的特定版本的 ruby，但是会报错软件是来自不明开发者身份，然后允许运行，

![06-06-tpH9JD](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2024/06-06-tpH9JD.png)

后面在社区大佬的解答下，怀疑是公司什么【安全软件】的拦截下导致下载的文件被打上了特殊的文件属性，导致运行不起来：

![06-06-OTX6SU](https://alphababy-blog.oss-cn-chengdu.aliyuncs.com/uPic/2024/06-06-OTX6SU.png)

<a name="y8fOq"></a>
## 解决办法：
参考：[https://github.com/Homebrew/brew/issues/17422](https://github.com/Homebrew/brew/issues/17422)
目前我时候的办法是：

```yaml
# 手动解压
tar -zxf ~/Library/Caches/Homebrew/portable-ruby-3.3.2.arm64_big_sur.bottle.tar.gz
# 移动到 brew 目录中
mv ./portable-ruby/3.3.2 /opt/homebrew/Library/Homebrew/vendor/portable-ruby/
# 去掉所有扩展属性
sudo xattr -c /opt/homebrew/Library/Homebrew/vendor/portable-ruby/3.3.2/bin/ruby
```
<a name="trEol"></a>
## 总结：
```yaml
在 macOS 中，xattr 是一个命令行工具，用于操作文件和目录的扩展属性（extended attributes）。扩展属性是与文件系统项（例如文件或目录）相关联的元数据，它们不同于传统的文件属性（如大小、修改日期等），可以用来存储额外的信息，例如文件的来源、自定义图标、备份状态等。

以下是 xattr 命令的一些常见用法：

查看扩展属性：
使用 xattr -l <file> 来列出指定文件或目录的所有扩展属性及其值。

添加扩展属性：
使用 xattr -w <attr-name> <value> <file> 来给指定文件或目录添加一个扩展属性，其中 <attr-name> 是属性名称，<value> 是要赋予属性的值。

删除扩展属性：
使用 xattr -d <attr-name> <file> 来删除指定文件或目录的一个扩展属性。

清除所有扩展属性：
使用 xattr -c <file> 可以清除指定文件或目录上的所有扩展属性。

复制扩展属性：
使用 xattr -x <attr-name> <file> 可以输出指定文件或目录的一个扩展属性的原始（十六进制）值。

xattr 在各种场景中都非常有用，尤其是在处理安全问题时，例如当你下载了一个应用程序而 macOS 提示它来自于未知开发者，系统可能会添加一个名为com.apple.quarantine的扩展属性，用以标记此文件已被隔离。你可以使用 xattr 命令查看这个属性，并在必要时将其删除。

请谨慎使用 xattr，因为修改或删除扩展属性可能会影响文件的正常使用或系统的安全功能。在做出任何更改之前，一定要确保你理解可能的后果。
```

chatGPT 关于 com.apple.quarantine 文件属性的解释
截至我最后了解的信息（2023年），com.apple.quarantine 是 macOS 系统用来标记从互联网下载的文件的一个扩展属性。当一个文件被下载下来时，macOS 会自动给该文件添加这个扩展属性，以指示该文件来自不受信任的来源，并且可能需要用户确认才能打开。这是 macOS 的网关隔离（Gatekeeper）功能的一部分，旨在防止恶意软件运行。
这个扩展属性会导致第一次尝试打开文件时弹出一个警告对话框，告知用户该文件是从互联网下载的，并询问用户是否确实要打开它。一旦文件被打开，系统通常会移除该属性，以表示该文件已被用户信任。
关于操作或查看这个扩展属性，你可以使用 xattr 命令。例如，查看一个文件的 com.apple.quarantine 属性可以使用：
```
1xattr -l <文件名>
```
移除该属性则可以使用：
```
1xattr -d com.apple.quarantine <文件名>
```
至于苹果官网的文档，苹果官方并不总是提供关于每一个系统特性的详细文档，特别是涉及到系统内部实现细节的功能。因而，关于 com.apple.quarantine 扩展属性的官方文档可能难以找到。苹果官网上的开发者文档（[Apple Developer Documentation](https://developer.apple.com/documentation)）提供了广泛的资源，但更多地是关注于 API 和开发者工具，而不是系统的内部安全机制。
要获取关于 com.apple.quarantine 或类似系统级特性的信息，通常需要查阅苹果的支持论坛、技术知识库或第三方技术博客和论坛，这些地方通常会有技术专家和经验丰富的用户分享他们的见解和技巧。此外，macOS 的官方安全指南和 Gatekeeper 的官方文档可能会间接提供相关信息。

**允许 macOS 运行非授信的软件**
**不建议这么做**
在 macOS 上，命令 sudo spctl --master-disable 是用来禁用系统的 Gatekeeper 功能。Gatekeeper 是 Apple 设计的安全特性，它确保只有受信任的应用程序（即在 App Store 中下载的应用程序或具有已知开发者 ID 签名的应用程序）可以在 macOS 上运行。这有助于防止恶意软件运行并保持系统的安全性。
使用 sudo spctl --master-disable 执行操作可能需要具备如下的背景：

- **sudo**：表示执行命令时使用超级用户权限，因为更改系统级安全设置需要更高的权限。
- **spctl**：是 Service Policy Control 的缩写，这是一种命令行工具，用来管理 Gatekeeper 的安全策略。
- **--master-disable**：是一个参数，告诉 spctl 命令禁用 Gatekeeper。

当你运行这个命令后，系统不再强制要求所有应用程序必须通过 Apple 的认证，用户可以自由安装和运行任何来源的应用程序，包括那些没有在 App Store 下载的应用，以及没有通过 Apple 发行的数字签名验证的第三方开发者的应用。
不过，请注意，禁用 Gatekeeper 可能会使你的 Mac 对潜在的安全威胁更加敏感，因此这种操作通常只在用户清楚自己正在做什么，以及需要暂时运行未签名的应用程序时才会使用。如果你确实需要这样做，一定要保证从可信赖的来源下载软件，避免潜在的安全风险。正常情况下，建议保持 Gatekeeper 功能开启来保护你的系统安全。
