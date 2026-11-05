# Bruno 官方二进制包

本地管理 `bruno-bin`，提供 `bruno`，与 AUR/其他来源的 `bruno` 冲突。
仅支持 x86_64，使用官方完整 DEB（含 Electron 及其资源），不混用系统 Electron。
构建不会安装应用或修改现有 Bruno 用户配置。

```sh
make srcinfo
make check
make build-bruno-bin
# 审阅构建产物后再自行决定是否安装；本仓库不自动安装。
```

构建额外需要 Arch 的 `asar`、Python 和 Node.js；不要使用 `makepkg -s/-i`
隐式安装。保留 Chromium 沙箱，包内 `chrome-sandbox` 设为 root 所有的 4755，
不添加 `--no-sandbox`。`package()` 复制源文件，支持复用源码重新打包。

## 版本与 AUR 对照

2026-11-05 核查：[官方 latest API](https://api.github.com/repos/usebruno/bruno/releases/latest)
为 [v4.3.0](https://github.com/usebruno/bruno/releases/tag/v4.3.0)，发布于 2026-10-22。
DEB SHA-256 与 API asset `digest` 一致：
`45117e3cc3c221801d10c8984c8e796f11bdf16d28e3a51b35e976603d3c3a02`。

[AUR bruno-bin](https://aur.archlinux.org/packages/bruno-bin) 当时为 4.2.1-1，
Git 提交 `341fd66858874ddf1b252dc580dd71072ee95ec5`（2026-10-01）；
AUR RPC 中 `bruno` 也为 4.2.1-1，两者均已标记过期。
AUR 二进制包直接展开 DEB，没有隐私修补，且依赖清单未完整覆盖 DEB 声明的
libnotify、libxss、libxtst、xdg-utils、at-spi、libuuid、libsecret；
未修正 DEB 中 0755 的 `chrome-sandbox` 为 setuid helper 所需权限。
这些是静态打包缺口，不代表已复现用户遇到的具体构建失败。
本次未构建旧 AUR 包，不能断言其失败原因。

## 自动更新和遥测

**以经过校验的 DEB 内 `resources/app.asar` 为依据**。
实际发布二进制包含开源 v4.3.0 标签里没有的更新器和偏好字段；不能仅依据
[开源 useTelemetry.js](https://github.com/usebruno/bruno/blob/v4.3.0/packages/bruno-app/src/providers/App/useTelemetry.js)
的简单计数器判断发布包行为，也不能用运行时环境变量覆盖已编译的 key。

- `src/store/preferences.js`：将 `autoupdate.downloadUpdates`、`telemetry.enabled`
  的默认值及缺失字段的 fallback 从 true 改为 false。已有显式偏好不被重写。
- `src/ipc/updater.js`：`registerAutoUpdater()` 在配置更新器、网络检查和定时器前
  检查 `process.resourcesPath/portable.json`，存在则直接返回。
  包内加入空 JSON 标记并移除 `app-update.yml`；因此即使旧偏好开启更新，也不启动更新器。
  portable 在该版本源码中只用于此更新守卫，不改变用户数据路径。
- `web/static/js/index.*.js`：移除两个编译进去的 PostHog key。
  事件捕获在 key 为空时返回；onboarding feature flag 获取同样检查 key，
  因此不会在偏好载入前或 opt-out 的旁路事件中初始化客户端。
  这比仅改默认值更严格：该包无法通过偏好开关重新启用 PostHog，更新也由 pacman 管理。
- `src/utils/license.js`：在请求序列化边界去掉激活、后台验证、试用及升级链接
  请求中的可选 `appDistinctId` / `posthogDistinctId`，避免授权链路继续携带遥测关联 ID。
  不删除授权必需的设备标识。

修补对上游代码模式和 key 数量有严格断言；更新改变结构时构建失败，须人工审阅。
`check()` 再次解包最终 ASAR，核对实际版本、默认值、无残留 key 和 portable 守卫。
`make check` 另含离线修补回归测试；它不下载 DEB，也不替代包构建检查。

禁用遥测不等于离线：用户请求、授权/试用、更新日志等功能仍可能联网。
例如显式激活试用会提交设备标识；本补丁不删除授权功能，不承诺屏蔽所有联网或所有身份信息。
未启动真实客户端、未进行 GUI/网络抓包验收，也未做干净 chroot 或 ARM 验证。

## 更新

1. 查询官方 latest Release，检查 tag、发布日期和 Linux amd64 DEB 的 API digest。
2. 修改 PKGBUILD 版本、修订号及固定校验值，核对许可文件。
3. 人工检查新 DEB 中偏好、更新器及所有 PostHog 调用，按需修改 `privacy.py` 和测试。
   不使用 `SKIP` 或跳过完整性验证来应付上游变化。
4. 更新 `privacy.py` 的 source 校验值，运行根目录 `make srcinfo`、`make check`、
   `make build-bruno-bin`，审阅归档内容、沙箱权限及版本。不自动发布或同步 AUR。

本次构建验证使用临时目录中独立的 `@electron/asar@4.3.1`，没有安装系统软件。
普通 `make build-bruno-bin` 因系统未装 `asar` 停止；核对其余依赖均满足后，
通过临时 PATH 提供 asar 并执行 `makepkg --nodeps` 成功完成源校验、修补、检查及打包。
这是本机受控验证，不是标准依赖检查完整通过的构建。
