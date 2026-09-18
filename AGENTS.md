# AI 维护指南

## 范围与入口

这是用于本地维护和构建的 Arch Linux 多包单仓库，**当前不向 AUR 发布**。
仓库根目录是唯一 Git 工作树，各包不是 submodule，也不要重新创建嵌套 `.git`。

| 路径 | 维护职责 |
| --- | --- |
| `dingtalk-bin/` | AUR 钉钉打包及本地启动器、桌面集成修复 |
| `shardbrowser/` | `shardx-launcher-bin`，目录名不等于包名；从 GitHub Releases 更新 |
| `Makefile` | 包清单 `PACKAGES`、统一检查、元数据生成和按包构建入口 |
| `README.md` | monorepo 工作流、远程配置和完整的 subtree 同步步骤 |

修改钉钉时阅读 [dingtalk-bin/README.md](dingtalk-bin/README.md) 中与任务相关的
适配说明；同步上游或修改仓库结构时阅读[根目录 README](README.md)。
不要为普通单包修复更新另一个包，或顺带添加发布工具、CI、自动更新任务。

## 命令与验证边界

以下命令都在仓库根目录执行：

| 命令 | 行为与边界 |
| --- | --- |
| `make` | 显示帮助，无下载、构建或安装 |
| `make check` | 离线检查 Shell 语法、两个包的 `.SRCINFO` 一致性、钉钉桌面入口及启动器回归测试 |
| `make srcinfo` | 从两个 PKGBUILD 重新生成各自的 `.SRCINFO`，会写文件 |
| `make build-dingtalk-bin` | 在钉钉目录运行 `makepkg`；可能下载源码，不安装依赖或应用 |
| `make build-shardbrowser` | 在 ShardX 目录运行 `makepkg`；可能下载源码，不安装依赖或应用 |
| `git diff --check` | 检查差异中的空白问题 |

- 检查依赖 Bash、make、makepkg、diff、desktop-file-validate 和 uv。
  启动器测试使用模拟程序，不会启动真实钉钉。
- `make check` **不验证源码校验值，不构建包，也不是干净 chroot 测试**。
  不要把它通过表述为运行功能、ARM 构建或全部依赖均已验证。
- 包版本、依赖、校验值或打包逻辑变更：生成元数据、运行 `make check`，
  再构建受影响的包；启动器变更同时维护 `dingtalk-bin/tests/test-wrapper.py`。
- 纯文档变更只需核对路径、命令和差异，不必下载软件或重复构建。
- 不自动改用 `makepkg -s/-i`、`sudo pacman` 或启动真实客户端；安装、
  退出正在运行的应用及修改全局桌面配置，应在用户授权的范围内进行。

## 打包修改顺序

1. 各包 `PKGBUILD` 是版本、依赖、源地址和校验值的事实来源；
   `.SRCINFO` 是生成文件，不独立手改它来掩盖与 PKGBUILD 的差异。
2. 修改被 `source` 引用的文件后，更新对应校验值，再运行 `make srcinfo`。
   元数据生成不会替你更新校验值。
3. 上游文件校验失败时先检查来源和内容变化，不用 `SKIP`、
   `--skipinteg` 或盲目重算校验值来绕过问题。
4. 钉钉本地修订在上游 `pkgrel` 后使用小数后缀；上游更新后重新选择修订号，
   不机械保留旧的本地值。源码版本不变的打包修复也要递增修订。
5. 新增包时更新根 `Makefile` 的 `PACKAGES`、根 README 的包表，
   提供 PKGBUILD 和生成的 `.SRCINFO`；按实际文件补充检查。
   当前桌面入口和启动器测试是显式指定的，不会自动发现新包测试。

## Git 与上游历史

- `main` 是整仓主分支，`origin` 是公开的 `oai404iao/aur`。
  不要提交凭据、私人应用日志、机器备份或构建下载。
- `aur-dingtalk` 仅用于获取 AUR 上游，当前本机设置了禁用的 push URL。
  不要启用 AUR 推送，也不要将整仓推向旧 shardbrowser 托管仓库。
  新 clone 不会继承这些本机 remote/config，配置方式见根 README。
- 本地改动使用聚焦分支与 Conventional Commits；普通本地修复可 squash。
  **上游 subtree 导入/更新不能 squash**，包括最终合入 `main` 时，
  否则会失去上游提交的祖先关系。
- 钉钉同步使用根目录的
  `git subtree merge --prefix=dingtalk-bin aur-dingtalk/master`，
  不是 `git merge aur-dingtalk/master`。先 fetch、审阅差异，再决定合并。
  完整命令及冲突处理见根 README，不复用旧独立仓库的 `local/upstream` 流程。
- 上游冲突先解决 PKGBUILD，再重新生成 `.SRCINFO`。
  保留仍必要的本地补丁；上游已有等效修复时再移除重复补丁。
- GitHub 推送与 AUR 发布是两件事。需要同步 GitHub 且已获授权时，
  显式使用 `git push origin main`；当前本机 `push.default=nothing`。

## 两个包的关键约束

### 钉钉

- `dingtalk-bin/dingtalk.sh` 已采用用户验证可用的 XCB、Qt/GTK Fcitx、
  GTK portal 默认值。环境变量只对未设置的值提供默认，**显式空值也应保留**。
- 保留启动器的工作目录、失败退出、`exec` 和完整 `"$@"` 参数转发；
  桌面入口的 `dingtalk://` 协议依赖参数不被丢弃。
- Qt Fcitx 插件来自包内；不要未经验证混入系统 Qt/Wayland 插件、
  替换整套 Qt/OpenSSL/CEF，或为修复单应用去改 chezmoi 全局设置。
- `package()` 应复制而不搬走源码，保持复用源码重打包的能力；
  移除捆绑库时限定具体 `.so` 库族并核对系统替代依赖，
  不恢复宽泛的 `libz*`、`libGL*` 删除规则。
- `service-terms-zh.html` 是受校验的固定协议快照，不改回构建时下载动态网页。
  更新快照时核对正文、来源和日期，更新校验值与包内 README 记录。
- 已知 `doctor` 旧库依赖、ARM 未验证范围及 INFO 日志刷屏见包内 README。
  不用伪造库链接或丢弃所有标准错误来掩盖这些问题。

### ShardX Launcher

- 更新入口是 `shardbrowser/update-pkgbuild.sh`，**必须在该包目录运行**；
  它依赖 curl/jq，会访问 GitHub、下载并删除同名 DEB、修改 PKGBUILD。
  不为检查文档或静态验证而运行它。
- 脚本以 Release API 的 digest 验证下载；缺少 digest 的确认不应被
  `--force` 自动跳过。更新后人工审阅差异，回根目录生成 `.SRCINFO` 并验证。
- 这是软件 Release 更新流程，不要把 `shardbrowser/` 当成另一份 AUR remote。

## 本地文件与临时工作

`src/`、`pkg/`、下载的 DEB 和包产物被忽略但不是待清理垃圾。
不要为了获得干净工作区执行 `git clean -fdx` 或清除旧包；清理需另行授权。
固定的钉钉协议 HTML 是跟踪文件，不能按下载文件处理。

临时测试和检查使用 `~/.local/state/agents/tmp/` 下新建的独立任务目录，
不写入 chezmoi，不存凭据，不自动清理其他任务。`make check` 已遵循此约定。
报告只列出实际完成的检查，区分构建成功、用户验证和仍未验证的运行功能。
