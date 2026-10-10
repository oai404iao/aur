# 本地 Arch Linux 包

个人维护的多包单仓库，目前只用于本地维护和构建，不向 AUR 发布。
各包平铺存放，共用根目录的 Git 仓库；不是 submodule，也没有嵌套 `.git`。

| 目录 | 实际包名 | 更新来源 |
| --- | --- | --- |
| [`dingtalk-bin/`](dingtalk-bin/) | `dingtalk-bin` | AUR 打包提交 + 本地桌面适配 |
| [`shardbrowser/`](shardbrowser/) | `shardx-launcher-bin` | ProxyShard/ShardBrowser 的 GitHub Releases |
| [`pnpm-bin/`](pnpm-bin/) | `pnpm-bin` | pnpm 官方 GitHub Releases 的 Linux x64 二进制 |
| [`pi/`](pi/) | `pi` | Pi 官方发布的 npm 包，通过 pnpm 固定生产依赖 |

钉钉的本地修复、运行限制及测试记录见
[`dingtalk-bin/README.md`](dingtalk-bin/README.md)。

## 常用操作

从仓库根目录执行：

```sh
make                       # 显示帮助，不下载或安装
make check                 # 离线语法、.SRCINFO 一致性、桌面入口和启动器测试
make srcinfo               # 修改 PKGBUILD 后重新生成所有包的 .SRCINFO
make build-dingtalk-bin     # makepkg 构建，不安装
make build-shardbrowser
make build-pnpm-bin
make build-pi
```

检查需要 Bash、make、makepkg、diff、desktop-file-validate、uv 和 Node.js。
`make check` 不下载源码、不验证源码校验值，也不替代完整构建或干净 chroot 测试。
实际构建由 makepkg 检查依赖和源文件校验；缺依赖时先审阅，再按需安装。
没有自动安装、发布、清理构建产物或静默更新的目标。
启动器测试的临时目录保留在 `~/.local/state/agents/tmp/`，供检查使用。

下载的 DEB、`src/`、`pkg/` 和构建产物由 Git 忽略，不纳入仓库。
各包的固定源码、补丁、许可快照仍按各自的 `.gitignore` 规则管理。

## 更新钉钉的 AUR 打包

这是拉取别人维护的打包提交，不是向 AUR 发布。首次克隆本 monorepo 后，
需自行添加上游 remote（Git 不会随 clone 复制 remote 配置）：

```sh
git remote add aur-dingtalk https://aur.archlinux.org/dingtalk-bin.git
git remote set-url --push aur-dingtalk disabled://aur-publishing-not-configured
```

当前迁移后的本地仓库已配置上述 remote，并设置 `push.default=nothing`。
monorepo 的 `origin` 为公开仓库 [oai404iao/aur](https://github.com/oai404iao/aur)；
向自己的 GitHub 仓库同步时显式使用 `git push origin main`。
不要把整仓推到旧 shardbrowser 仓库或 AUR。

工作区干净时，从根目录查看上游更新：

```sh
git fetch aur-dingtalk
git log --oneline HEAD..aur-dingtalk/master
git diff "$(git merge-base HEAD aur-dingtalk/master)" aur-dingtalk/master \
    -- PKGBUILD .SRCINFO dingtalk.sh com.alibabainc.dingtalk.desktop
```

确认需要后，在开发分支合并到包目录：

```sh
git switch -c chore/update-dingtalk
git subtree merge --prefix=dingtalk-bin aur-dingtalk/master \
    -m "chore(dingtalk-bin): merge AUR updates"
# 解决冲突，保留仍需要的本地修复，调整 pkgrel 和源文件校验值。
make srcinfo
make check
make build-dingtalk-bin
# 检查差异并逐项暂存，提交必要的修正。
git switch main
git merge --ff-only chore/update-dingtalk
```

如果 subtree merge 冲突，先解决 PKGBUILD，再生成 `.SRCINFO`，
逐项暂存并完成合并提交；放弃尚未完成的合并可用 `git merge --abort`。
如果上游已修复某项问题，移除等效的本地补丁。

**上游 subtree 导入和更新不能 squash**：需要保留原始提交的祖先关系，
让下次同步知道哪些提交已合并。`main` 已前进时，应使用保留历史的普通 merge
整合更新分支，不要强制覆盖 main。普通本地修复可按独立分支 + squash 维护。
不要在 monorepo 根目录执行 `git merge aur-dingtalk/master`，
它不是针对包子目录的合并。

## 更新 ShardX Launcher

此目录沿用原来的本地维护脚本，并不是从 AUR 导入的仓库：

```sh
cd shardbrowser
./update-pkgbuild.sh
cd ..
make srcinfo
make check
make build-shardbrowser
```

更新脚本会访问 GitHub、下载 DEB 并核对 Release API 的 SHA-256 digest；
缺少 digest 时会要求确认。它会修改 PKGBUILD，不会替你提交，
需人工审阅版本、校验值和实际构建结果；不要为省事使用 `--force`。
脚本还需要 curl 和 jq。本次迁移未改写它的行为。

## 管理 pnpm-bin

pnpm-bin 的安装、版本更新及切回官方包步骤见
[`pnpm-bin/README.md`](pnpm-bin/README.md)。它是本地新增包，不使用 subtree 同步。

## 管理 pi

[`pi/README.md`](pi/README.md) 说明如何使用 pnpm 固定上游发布包的生产依赖，
构建本地 `pi` 包，以及如何更新和切回仓库包。pnpm 只用于打包，
不修改 Pi 内部包管理行为；构建不会安装或替换正在运行的 Pi。

## 历史迁移

两个仓库使用非 squash 的 Git subtree 导入，原始提交 ID 保持不变：

- `dingtalk-bin`：原 `local` 分支，导入点 `aa54e72`；
  AUR 基线 `84473a0`，包含此前的完整 AUR 历史和本地修复。
- `shardbrowser`：原 `main` 分支，导入点 `479dc6a`。

原仓库历史保留其原始根目录路径；导入后的修改使用包目录前缀。
因此 `git log -- dingtalk-bin/` 不是查看所有导入前历史的方式。
例如用 `git log aa54e72` 或 `git log 479dc6a` 查看旧历史，
用 `git show <提交>` 查看具体变更。

旧 shardbrowser 托管仓库没有被修改或推送。原 `.git` 和完整 bundle
已在迁移时另外保留，不将这类机器本地备份放入 Git。
