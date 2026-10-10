# pi

本地维护的 Arch Linux `pi` 包，不向 AUR 发布，也不使用 subtree。
使用 [Pi 上游](https://github.com/earendil-works/pi) 已编译的 npm 发布包，
通过 **pnpm** 安装固定的生产依赖，再由 makepkg 打包、pacman 管理。
不是从 TypeScript monorepo 重新编译，也不是 `pnpm add -g`。
目前仅声明和验证 `x86_64`。

## 构建与安装

需要 Node.js >=22.19.0、pnpm >=12 和 libxcb。仓库的 `pnpm-bin` 提供 pnpm
依赖，不要求先切换回官方 pnpm。

从仓库根目录执行：

```sh
make check
make build-pi
# 人工确认后安装；与 AUR/archlinuxcn 的 pi 同名，按普通包升级替换。
sudo pacman -U pi/pi-1.1.0-1-x86_64.pkg.tar.zst
pi --version
```

构建需要联网下载锁定的 npm 包，不安装依赖、不提权、不覆盖系统文件，
也不访问现有 Pi 配置、凭据和会话。不要用 `--overwrite` 或同时进行全局安装。
安装前退出 Pi、安装后重新启动即可；不要在正在运行的会话中替换文件。
本仓库不修改用户的 PATH 或 Pi 配置目录。

包名仍是 `pi`；AUR helper 或 archlinuxcn 以后可能再次升级它。
如需长期保留本地包，需自行决定是否对 `pi` 设置 pacman 的 `IgnorePkg`，
并在更新本地包或切回仓库包时人工处理。此仓库不修改全局 pacman 配置。

## 打包边界

- `pnpm-lock.yaml` 从上游 Release 的安装用 `package-lock.json` 转换而来，
  固定完整依赖版本与 registry integrity；不会在每次构建时重新解析 latest。
- 使用 `--prod --frozen-lockfile --ignore-scripts --ignore-pnpmfile`；
  不运行 npm，也不执行依赖的安装脚本。pnpm store 留在 `src/pnpm-store/`。
- hoisted 布局和 copy 导入避免依赖外部 pnpm store 的链接。
  保留完整 `node_modules`，包括 SDK、类型、文档、示例、worker、WASM
  和平台模块；不手工选择 monorepo 子包，也不删除可选依赖。
- 主体安装到 `/usr/lib/pi/node_modules/`；
  `/usr/bin/pi` 指向上游声明的 `dist/bundle/cli.js`；
  `/usr/share/doc/pi` 链接到 coding-agent 包目录，具体文档在其 `docs/` 下。
- pnpm 只参与打包。**不改 Pi 内部的 `pi install` 等包管理行为**；
  需要其 npm 操作时安装可选依赖 npm。Pi 自身升级应走本仓库和 pacman，
  不运行 `sudo pi update` 或 `sudo npm/pnpm install -g` 覆盖包文件。

`make check` 只做离线静态检查。
`make build-pi` 的 `check()` 才会实际验证 CLI 版本与 help、SDK 导入、
esbuild、图像 WASM、Linux native 模块、必需资源及依赖链接是否留在安装树内。
测试在独立临时配置下运行，不发起模型调用，测试目录保留。
这些检查不等于交互功能、全部扩展、其他架构或干净 chroot 验证。

## 更新版本

1. 选择 [正式 Release](https://github.com/earendil-works/pi/releases)，
   核对 release tag、npm 发布版本、Node.js 要求与 changelog。
2. 在 `~/.local/state/agents/tmp/` 创建独立任务目录；下载该 Release 的
   `pi-coding-agent-install-package.json` 和
   `pi-coding-agent-install-package-lock.json`，分别保存成 `package.json`
   和 `package-lock.json`。将下载文件的 SHA-256 与
   `https://api.github.com/repos/earendil-works/pi/releases/tags/v<VERSION>`
   中各资产的 digest 比对。
3. 复制本目录的 `pnpm-workspace.yaml` 到任务目录；
   根据上游 manifest 同步 `overrides`（当前为 `protobufjs: 7.6.6`）。
   在任务目录运行 `pnpm --store-dir ./pnpm-store import`，
   审阅生成锁文件：版本应与上游锁一致，每项必须有 integrity，
   已有的上游 integrity 不应改变。上游未给 integrity 的项须与 registry
   对应版本的 `dist.integrity` 核对；不要用忽略校验的选项绕过失败。
4. 将生成的 `pnpm-lock.yaml` 复制回本目录，更新 `PKGBUILD` 的 `pkgver`、
   `pkgrel`、安装 manifest 与 LICENSE 校验值，以及本地文件校验值。
   LICENSE 从相同 tag 下载并审阅。同步本文安装示例。
5. 回根目录运行 `make srcinfo`、`make check`、`make build-pi`。
   检查包内容，尤其是可执行入口、SDK、native 模块、文档及依赖链接；
   安装前应从独立解包目录再运行一次 `check-package.mjs <解包目录>/usr/lib/pi <VERSION>`。

当前 `1.1.0` 的上游安装锁文件 SHA-256 为
`89a53fa67297177bad42d71e9eb9c7eaeb9c7fc34d3cfb6800c1b38fbc293ebb`；
由 pnpm `12.9.1` 转换，146 个唯一包版本与上游锁一致。
其中 8 个 Pi 自有包的 integrity 来自 npm registry，上游安装锁未提供它们。

## 切回仓库包

如果启用了 archlinuxcn，可人工运行 `sudo pacman -S archlinuxcn/pi`；
仅使用 AUR 时，重新审阅并构建 AUR 的 `pi`，再用 `pacman -U` 安装。
如曾配置 IgnorePkg，先自行调整。不要直接删除 `/usr/lib/pi`；
由 pacman 处理新旧文件清单。此操作不需要删除 Pi 的用户配置和会话。
