# rbw 个人维护分支

实际包名为 `rbw-oai404iao-git`，提供并冲突于 `rbw`，包含 `rbw` 和
`rbw-agent`、Bash/Zsh/Fish 补全、MIT 许可及上游 README/CHANGELOG。
仅构建 x86_64，本仓库不向 AUR 发布。

## 来源与版本

源码来自公开 fork [oai404iao/rbw](https://github.com/oai404iao/rbw) 的
`fix/refresh-token-rotation` 分支，不使用本机源码或认证 URL。
每次构建都会获取该分支最新提交；维护修复时继续推送到同一分支。
Cargo 使用上游 `Cargo.lock`，下载依赖时 `--locked`，编译时 `--frozen`。
禁用 makepkg 的 LTO，避免 ring 的 GCC LTO 原生对象与 Rust LLD 链接器不兼容。

Git VCS source 的 `SKIP` 不代表固定归档的校验失败被忽略：分支本身会移动，
没有稳定的归档 SHA-256。`pkgver()` 由最近数字版本 tag、距 tag 的提交数和
短 commit ID 生成，例如 `1.15.0.r2.gabcdef0`；makepkg 会更新 PKGBUILD 的
`pkgver`。安装包内 `usr/share/doc/rbw-oai404iao-git/SOURCE` 记录来源、分支、
完整 commit ID 及 Cargo.lock 的 SHA-256，可与公开 Git 历史核对。
这不是签名验证，也不是固定 commit 的可重复构建承诺。

## 构建与更新

在仓库根目录执行：

```sh
make check
make build-rbw
make srcinfo              # 构建可能更新 pkgver；重新生成元数据
make check
git diff --check
```

需要 Arch 基础构建工具、Git、Cargo/Rust 和 PKGBUILD 中声明的运行依赖；
makepkg 检查缺失依赖，但这些命令不安装依赖或软件。构建产物保留在本目录；
`src/`、`pkg/`、Git 镜像缓存 `rbw/` 和包归档不进入 Git，不自动清理。

构建仅执行新二进制的 `gen-completions` 和 `--version`，不会运行其他 rbw
命令或启动 agent。`check()` 是打包烟测，不是 refresh-token 轮换行为测试；
`make check` 仍只是仓库离线检查，也不代表干净 chroot 或真实 vault 验证。
补全脚本在用户安装并交互使用时可能调用 rbw；构建时只生成，不加载补全。
安装、切换系统包、重启现有 agent 和真实 vault 测试需另行决定。

## 切换注意事项

应在获准的维护窗口内同时切换软件包并重启已有的 `rbw-agent`：旧 agent
不会遵守新版本的跨进程刷新锁，仅替换磁盘上的程序不能修复正在运行的旧进程。
本包没有自动安装钩子或自动重启行为。

已经失效的 refresh token 无法由此修复恢复，需要重新认证一次。不要自动删除
本地缓存、配置或 vault；先安排维护窗口，再由用户执行认证及功能验证。
