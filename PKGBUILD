# Maintainer: zhullyb <zhullyb [at] outlook dot com>
# Maintainer: yjun <jerrysteve1101 at gmail dot com>
# Contributor: Bruce Zhang <zttt183525594@gmail.com>
# Contributor: witt <1989161762 at qq dot com>

pkgname=dingtalk-bin
_pkgname=dingtalk
_pkgname2=com.alibabainc.dingtalk
# https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Update/other/amd64/linux_dingtalk_update_package_gray.json
pkgver=8.2.8.260904001
pkgrel=1.1
pkgdesc="钉钉"
arch=("x86_64" 'aarch64')
url="https://www.dingtalk.com/"
license=("custom")
options=('!strip')
depends=('glu' 'gtk2' 'libxcrypt-compat'
    # System replacements for the bundled libraries removed below.
    'glibc' 'gcc-libs' 'curl' 'harfbuzz' 'mesa' 'libglvnd' 'zlib'
    # Main executable, CEF, audio plugins and bundled Qt's XCB backend.
    'gtk3' 'libsm' 'nss' 'alsa-lib' 'libpulse'
    'libxkbcommon-x11' 'xcb-util-wm' 'xcb-util-image'
    'xcb-util-keysyms' 'xcb-util-renderutil'
)
makedepends=("patchelf")
optdepends=('zenity: fix crashes when downloading files, not required on kde.'
    'libxss: fix tray icon functionality in gnome.'
    'qt5-wayland: experimental native Wayland support; must be compatible with bundled Qt'
)
provides=('com.alibabainc.dingtalk' 'dingtalk')
conflicts=('com.alibabainc.dingtalk')
replaces=('com.alibabainc.dingtalk')
source_x86_64=("${_pkgname}_${pkgver}-x86_64.deb::https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/${_pkgname2}_${pkgver}_amd64.deb")
source_aarch64=("${_pkgname}_${pkgver}-aarch64.deb::https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/${_pkgname2}_${pkgver}_arm64.deb")
# Keep a reviewed snapshot: the live agreement changes independently of releases.
source=("service-terms-zh.html"
    "${_pkgname2}.desktop"
    "dingtalk.sh"
    "${_pkgname2}.svg"
)

# DebSource & pkgver can be get here: https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Update/other/linux_dingtalk_update.json
sha512sums=('997fe19e8a056c84a65b3f4c438c0b3e97d1a6acd6f3d17c54846216afb70a757cbc81750712e8a4b8311e46c7cddfb636370355f443fdcaf4322b2dbd206215'
            '87c539df12e76400315af7b9f94a5c259c1a61adf93b6f84442b43bb154d4da7d68cfd6c4d62fe2fe3d50d155fff39fb3989e184252b3de493d44ff28464170e'
            '166812149f6d8c628662f507b543c6f73e20d9aa66b869213f07340229d2f8b408e07d7a127d26c9df855ea3faea0d14ce01e63f7804273dede2903c2750db2f'
            '5f05f90704526fbd16371f6f9deaa171a3cac25a103b21daba72a3028ab7cdf9b566a3ac7842c6ce88d30cc29fe0c8b989c77aa36daab73793a827a1a0d6c775')
sha512sums_x86_64=('5a1adf50cb7f36443f4b39c436b980fdbbfa50814367f3be8a6a54c67a07cf1dd96c0ecabd08bb60936e46e77d715073ff5f9ec0ce6dc918ba269f8bccd93a2e')
sha512sums_aarch64=('9778633c98782939f1a7ddf8b9bf44b119ad2fc57dfa925c662977916f98f5e5eead2bf8e5e6ce3a1570a7071785659deb28b70d77b8a8223ffeee933dc6aad6')

prepare() {
    tar -Jxf data.tar.xz -C "${srcdir}"
}

package() {
    cd "${srcdir}"

    mkdir -p "${pkgdir}/opt/${_pkgname}/release"
    mkdir -p "${pkgdir}/usr/share/doc/"
    cp -a "opt/apps/${_pkgname2}/files/"*-Release.*/. "${pkgdir}/opt/${_pkgname}/release/"
    cp -a "opt/apps/${_pkgname2}/files/version" "${pkgdir}/opt/${_pkgname}/"
    cp -a "opt/apps/${_pkgname2}/files/doc/${_pkgname2}" "${pkgdir}/usr/share/doc/${_pkgname}"

    # binary wrapper
    install -Dm755 "${srcdir}/dingtalk.sh" "${pkgdir}/usr/bin/dingtalk"

    # desktop entry
    install -Dm644 "${_pkgname2}.desktop" -t "${pkgdir}/usr/share/applications/"

    install -Dm644 "${srcdir}/${_pkgname2}.svg" "${pkgdir}/usr/share/icons/hicolor/scalable/apps/${_pkgname}.svg"

    # license
    install -Dm644 "service-terms-zh.html" "${pkgdir}/usr/share/licenses/${_pkgname}/service-terms-zh.html"

    patchelf --clear-execstack "${pkgdir}/opt/dingtalk/release"/{dingtalk_dll,libconference_new}.so

    # fix chinese input in workbench
    rm -f "${pkgdir}/opt/${_pkgname}/release/libgtk-x11-2.0.so."*

    # Remove resources for other platforms.
    rm -rf "${pkgdir}/opt/${_pkgname}/release"/Resources/{i18n/tool/*.exe,qss/mac,web_content/NativeWebContent_*.zip}

    # Use system libraries, not arbitrary libz*/libGL* matches.
    # Keep unrelated libraries (e.g. libzstd, libzip, libGLES) if upstream adds them.
    rm -f "${pkgdir}/opt/${_pkgname}/release"/{libm.so.6,libstdc++.so,libstdc++.so.*,libharfbuzz.so,libharfbuzz.so.*,libgbm.so,libgbm.so.*,libcurl.so.4,libz.so,libz.so.*,libGLX.so,libGLX.so.*,libGLdispatch.so,libGLdispatch.so.*}
}
