# pnpm-bin

本地维护的 Arch Linux 包，使用 [pnpm 上游正式发行包](https://github.com/pnpm/pnpm/releases)；
不向 AUR 发布。目前只支持、验证 `x86_64`。

建立此包是为了绕开 extra/pnpm 12.9.0-1 实际打包 pnpm 11.28.3 的
[问题 #29](https://gitlab.archlinux.org/archlinux/packaging/packages/pnpm/-/work_items/29)。

## 构建与安装

从仓库根目录执行：

```sh
make check
make build-pnpm-bin
# 人工确认后安装；pacman 会提示移除冲突的 pnpm。
sudo pacman -U pnpm-bin/pnpm-bin-12.10.1-1-x86_64.pkg.tar.zst
pnpm --version
```

`provides=("pnpm=$pkgver")` 满足对 pnpm 的依赖，`conflicts=('pnpm')`
防止与官方包同时占用命令。不使用 `--overwrite`，也不直接覆盖系统文件。
仓库的构建命令不会自动安装、提权或修改 PATH。

主程序和完整 `dist/` 放在 `/usr/lib/pnpm/`，保留上游附带的 node-gyp
及其依赖；`pnpm`、`pn` 是主程序入口，`pnpx`、`pnx` 包装为 `pnpm dlx`。
pnpm 本体无需 Node.js；运行 Node.js 项目和相关生命周期脚本仍需要运行时，
编译原生 addon 还需要 Python、make 和编译器。

## 更新

1. 选择上游正式 Release，修改 `PKGBUILD` 的 `pkgver`，将 `pkgrel` 重置为 1。
2. 从 Release API 核对 `pnpm-linux-x64.tar.gz` 资产的 SHA-256 digest：
   `https://api.github.com/repos/pnpm/pnpm/releases/tags/v<VERSION>`。
   下载归档并验证 digest；同时审阅新版本 LICENSE 并更新其校验值。
   不使用 `SKIP` 或在校验失败后盲目替换校验值。
3. 修改本地 `pnpx` 时更新其 SHA-256；同版本打包修复递增 `pkgrel`。
4. 在根目录运行 `make srcinfo`、`make check`、`make build-pnpm-bin`。
   构建的 `check()` 会核对实际二进制版本与 `pkgver`，并检查 node-gyp 文件。
5. 审阅包内容和差异，再人工安装。这里只维护固定版本，不自动追踪 latest。

`make check` 是离线静态检查，不执行或下载上游程序；
`make build-pnpm-bin` 才会校验下载并执行上述版本检查。
这不等同于完整依赖安装测试或干净 chroot 验证。

## 切回官方包

确认 extra 修复后，人工运行 `sudo pacman -S pnpm` 并确认移除冲突的
`pnpm-bin`。切回后再次检查 `pnpm --version`，不要仅依据 pacman 的包版本。
