# dingtalk-bin：本地维护

基于 [AUR dingtalk-bin](https://aur.archlinux.org/packages/dingtalk-bin)，
初始基线为 `84473a0`（`8.2.8.260904001-1`）。

- `upstream`：AUR Git 仓库，保留完整提交历史。
- `local`：本地维护分支，不向 AUR 推送。仓库设置了 `push.default=nothing`，
  防止无参数 `git push` 意外发布；显式指定远程仍可推送，不应对 upstream 使用。
- 本地修订使用 `pkgrel=1.2`：在上游 `1` 之后、`2` 之前。
  上游更新后，基于新的 `pkgrel` 重新选择本地小数修订号。

## 本地改动

- 启动器使用 `exec` 并完整转发参数；默认使用 XCB、Fcitx 和 GTK portal，
  保留用户设置的环境变量，包括显式空值。
- 修正桌面入口重复键；保留 `dingtalk://` 协议入口。
- `package()` 复制而不搬走源文件，支持 `makepkg --noextract --force` 重打包。
- 将宽泛的删库通配符限制到指定 `.so` 库族，并声明其系统替代依赖。
- 根据 x86_64 DEB 的 ELF 依赖补充 GTK3、NSS、音频和 XCB 后端依赖。
- 服务协议使用仓库内固定快照，不在构建时访问会变化的在线协议页面。

### 桌面集成

启动器对未设置的变量使用以下默认值，只影响钉钉及其子进程，
不修改 chezmoi 或桌面全局环境：

```sh
QT_QPA_PLATFORM=xcb
QT_IM_MODULE=fcitx
GTK_IM_MODULE=fcitx
GTK_USE_PORTAL=1
QT_AUTO_SCREEN_SCALE_FACTOR=1
```

Qt 使用包内的 Fcitx 插件，GTK 组件需要系统 `fcitx5-gtk`；
Fcitx 服务需要在桌面会话中运行。Wayland 会话需要可用的 XWayland。
GTK 原生文件选择器通过 `xdg-desktop-portal` 使用桌面配置的后端。
本机 Niri 已配置 `org.freedesktop.impl.portal.FileChooser=gnome;gtk;`，
包不替用户修改这项配置，也不强制安装某一种后端。

用户已在 Niri 会话验证上述四项桌面集成变量可解决输入法和文件选择器问题。
其他桌面或输入法可单独覆盖，例如：

```sh
QT_IM_MODULE=ibus GTK_IM_MODULE=ibus dingtalk
GTK_USE_PORTAL=0 dingtalk
```

升级后需从托盘完整退出再启动，已有进程不会获得新的环境变量。
上游 `MojoThreadServiceDelegate::PostDealyedTask` 的 INFO 日志刷屏
未在此修订中处理；不丢弃标准错误，也不屏蔽应用日志。

### 服务协议快照

`service-terms-zh.html` 是 2026-09-18 下载的原始 HTML，来自：

https://terms.alicdn.com/legal-agreement/terms/suit_bu1_dingtalk/suit_bu1_dingtalk202010200940_84493.html

它沿用上游选择的协议，不表示软件被重新许可。DEB 的 `copyright`
仍是未填写的模板，不能用来替代协议。更新快照时应人工核对页面正文，
记录来源及日期，并更新 PKGBUILD 校验值；不要用 `SKIP` 或
`--skipinteg` 绕过校验。快照固定的是构建输入，不保证网页内容永远有效。
本次快照正文标注更新于 2024-06-26、生效于 2024-07-03。

## 构建与检查

```sh
bash -n PKGBUILD dingtalk.sh
desktop-file-validate com.alibabainc.dingtalk.desktop
makepkg --verifysource
makepkg
# 验证可以复用同一份已解包源码：
makepkg --noextract --force
```

依赖缺失时先审阅，再选择是否执行 `makepkg -s` 安装依赖。
以上命令不会安装钉钉。构建产物和下载的 DEB 不纳入 Git。

启动器回归测试不安装或运行钉钉，使用保留的临时模拟程序：

```sh
mkdir -p "$HOME/.local/state/agents/tmp"
task_dir=$(mktemp -d "$HOME/.local/state/agents/tmp/dingtalk-check.XXXXXXXX")
TMPDIR="$task_dir" uv run --no-project python tests/test-wrapper.py
```

变更源文件后核对并更新 `sha512sums`，然后生成元数据：

```sh
makepkg --printsrcinfo > .SRCINFO
git diff --check
```

## 查看与合并 AUR 更新

先确保本地改动已提交、工作区干净：

```sh
git switch local
git fetch upstream
git log --oneline HEAD..upstream/master
git diff HEAD...upstream/master -- PKGBUILD .SRCINFO dingtalk.sh \
    com.alibabainc.dingtalk.desktop
```

确认更新范围后再合并，不自动更新、不盲目覆盖本地修复：

```sh
git merge --no-ff --no-commit upstream/master
# 审阅/解决冲突，调整本地 pkgrel、源文件校验值和依赖。
# .SRCINFO 是生成文件：先解决 PKGBUILD，再重新生成。
makepkg --printsrcinfo > .SRCINFO
# 执行上面的检查与构建，逐项 git add 确认后的文件。
git commit -m "chore: merge AUR dingtalk-bin update"
```

上游同步采用普通 merge，保留上游祖先关系，避免下次重复合并同一批提交；
不对上游同步使用 squash。放弃尚未提交的合并可用 `git merge --abort`。
如果上游已修好某个问题，移除等效的本地补丁。

## 尚待运行验证

- 本轮检查针对 x86_64；保留 aarch64 上游源和校验值，未进行 ARM 构建验证。
- 默认使用 `xcb`。包内只有 XCB 等插件，没有 Wayland 插件；
  系统 `qt5-wayland` 与捆绑 Qt 可能不兼容，安装它不保证原生 Wayland 可用。
- `doctor` 及其 GTK 扩展依赖旧 `libpangox-1.0.so.0`，
  在所检查的 DEB 和本机系统中均未找到。未删诊断程序或伪造库链接；
  这项诊断功能仍有已知加载风险。
- ELF 检查不能覆盖所有 `dlopen` 和桌面功能；输入法和文件选择器
  已有本机用户验证，托盘、音视频及会议功能仍需测试。
  不擅自替换内置 Qt/OpenSSL/CEF。

### 初次验证记录（2026-09-18）

- Shell 语法、桌面入口校验、5 项启动器回归测试通过。
- x86_64 源文件校验及 `makepkg` 完整构建通过；未安装或运行客户端，
  未使用干净 chroot。
- `makepkg --noextract --force` 完成，前后归档文件清单一致，源文件保留。
  此次重打包日志出现一次 `libfakeroot internal error: payload not recognized!`；
  后续检查确认归档所有条目的 UID/GID 均为 0，启动器和协议内容正确，
  但没有将这次重打包视为无告警构建。
- 两个目标库的可执行栈标记已清除，指定的捆绑库已移除。
  按库文件名检查最终包的 ELF 依赖，本机未能匹配的只剩
  `libpangox-1.0.so.0`；这不是完整的动态加载路径或运行时验证。
