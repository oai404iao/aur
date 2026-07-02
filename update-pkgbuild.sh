#!/usr/bin/env bash
set -euo pipefail

# 自动获取 GitHub 最新 Release 并更新 PKGBUILD
# 用法: ./update-pkgbuild.sh

repo='ProxyShard/ShardBrowser'
pkgbuild='PKGBUILD'

echo '=> 查询最新 release...'
release_json=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest")
tag=$(printf '%s' "$release_json" | jq -r '.tag_name')
version=${tag#v}

echo "=> 最新版本: ${version}"

debfile="ShardX.Launcher_${version}_amd64.deb"
deburl="https://github.com/${repo}/releases/download/${tag}/${debfile}"

echo '=> 下载 .deb 计算 sha256sum...'
curl -fsSL -o "${debfile}" "${deburl}"
deb_sha=$(sha256sum "${debfile}" | awk '{print $1}')
rm -f "${debfile}"

echo "=> .deb checksum: ${deb_sha}"

echo '=> 获取 LICENSE sha256sum...'
license_url="https://raw.githubusercontent.com/${repo}/${tag}/LICENSE"
license_sha=$(curl -fsSL "${license_url}" | sha256sum | awk '{print $1}')

echo "=> LICENSE checksum: ${license_sha}"

# 读取当前 PKGBUILD 中的两个 sha256
old_deb_sha=$(grep -oE '[a-f0-9]{64}' "${pkgbuild}" | sed -n '1p')
old_license_sha=$(grep -oE '[a-f0-9]{64}' "${pkgbuild}" | sed -n '2p')

echo '=> 更新 PKGBUILD...'
sed -i "s/^pkgver=.*/pkgver=${version}/" "${pkgbuild}"
sed -i "s/^pkgrel=.*/pkgrel=1/" "${pkgbuild}"
sed -i "s/${old_deb_sha}/${deb_sha}/" "${pkgbuild}"
sed -i "s/${old_license_sha}/${license_sha}/" "${pkgbuild}"

echo '=> 完成。请检查 diff 后提交: makepkg -si'
git diff "${pkgbuild}"
