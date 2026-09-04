# Maintainer: ProxyShard <support@proxyshard.com>

pkgname=shardx-launcher-bin
pkgver=2.0.1
pkgrel=1
pkgdesc='Anti-detect browser launcher for the ShardX Chromium engine'
arch=('x86_64')
url='https://github.com/ProxyShard/ShardBrowser'
license=('MIT')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'ca-certificates'
  'cairo'
  'cups'
  'gcc-libs'
  'glibc'
  'gtk3'
  'libayatana-appindicator'
  'libxcomposite'
  'libxdamage'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'libxshmfence'
  'mesa'
  'nspr'
  'nss'
  'pango'
  'ttf-liberation'
  'unzip'
  'webkit2gtk-4.1'
)
makedepends=('desktop-file-utils')
optdepends=(
  'xdg-utils: open external links from the launcher'
)
provides=("shardx-launcher=${pkgver}" "shard-x-launcher=${pkgver}")
conflicts=('shardx-launcher' 'shard-x-launcher')
options=('!strip' '!debug')
install="${pkgname}.install"

_debfile="ShardX.Launcher_${pkgver}_amd64.deb"
source=(
  "${_debfile}::${url}/releases/download/v${pkgver}/${_debfile}"
  "LICENSE::https://raw.githubusercontent.com/ProxyShard/ShardBrowser/v${pkgver}/LICENSE"
)
noextract=("${_debfile}")
sha256sums=(
  '88b143f6f048424646e832ac0e8b50f1a87f3d9408011c61e9a6e43f0e7fc011'
  '2025860f56aed0594d00ae13af01f36529e4dc46f1967f7f274b33631f94edb1'
)

prepare() {
  rm -rf deb-data
  mkdir -p deb-data

  bsdtar -xOf "${_debfile}" data.tar.gz | bsdtar -xzf - -C deb-data

  mv "deb-data/usr/share/applications/ShardX Launcher.desktop" \
    'deb-data/usr/share/applications/shardx-launcher.desktop'

  sed -i \
    -e 's/^Categories=.*/Categories=Network;WebBrowser;/' \
    -e 's/^Comment=.*/Comment=Anti-detect browser launcher for ShardX Chromium/' \
    'deb-data/usr/share/applications/shardx-launcher.desktop'
}

check() {
  desktop-file-validate 'deb-data/usr/share/applications/shardx-launcher.desktop'
}

package() {
  cp -a deb-data/usr "${pkgdir}/"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
