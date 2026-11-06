#!/usr/bin/env bash
set -euo pipefail

# 获取 GitHub Release 并更新 PKGBUILD（默认 latest）
# 用法: ./update-pkgbuild.sh [--tag v<VERSION>]
#
# 安全说明：
#   脚本会从 GitHub Release API 读取 .deb 的 digest（sha256），下载后
#   本地重新计算并比对；只有完全一致才更新 PKGBUILD。如果上游没有
#   digest，则提示风险并要求人工确认。

repo='ProxyShard/ShardBrowser'
pkgbuild='PKGBUILD'
endpoint=latest
if [[ $# -ne 0 ]]; then
  if [[ $# -ne 2 || $1 != --tag || ! $2 =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo '用法: ./update-pkgbuild.sh [--tag v<VERSION>]' >&2
    exit 1
  fi
  endpoint="tags/$2"
fi

echo "=> 查询 release: ${endpoint}..."
release_json=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/${endpoint}")
tag=$(printf '%s' "$release_json" | jq -r '.tag_name')
version=${tag#v}

echo "=> 选定版本: ${version}"

debfile="ShardBrowser.Launcher_${version}_amd64.deb"
deburl="https://github.com/${repo}/releases/download/${tag}/${debfile}"
if ! printf '%s' "$release_json" | jq -e --arg name "$debfile" '.assets | any(.name == $name)' >/dev/null; then
  echo "!! release 缺少 ${debfile}" >&2
  exit 1
fi

# 从 GitHub API 读取官方 digest
expected_digest=$(printf '%s' "$release_json" | jq -r --arg name "${debfile}" '.assets[] | select(.name == $name) | .digest')

if [[ -z "$expected_digest" || "$expected_digest" == 'null' ]]; then
  echo '!! 上游 release 没有提供该 .deb 的 digest。' >&2
  echo '   本地计算的 hash 只能保证文件完整性，不能保证未被篡改。' >&2
  echo -n '   是否仍要更新 PKGBUILD? [y/N] ' >&2
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 1
  expected_digest=''
else
  echo "=> 官方 digest: ${expected_digest}"
fi

echo '=> 下载 .deb...'
curl -fsSL -o "${debfile}" "${deburl}"

deb_sha=$(sha256sum "${debfile}" | awk '{print $1}')
echo "=> 本地 sha256: sha256:${deb_sha}"

if [[ -n "$expected_digest" ]]; then
  if [[ "sha256:${deb_sha}" == "$expected_digest" ]]; then
    echo '=> digest 验证通过'
  else
    echo '!! digest 不匹配，下载文件可能已被篡改。' >&2
    rm -f "${debfile}"
    exit 1
  fi
fi

rm -f "${debfile}"

echo '=> 获取 LICENSE sha256...'
license_url="https://raw.githubusercontent.com/${repo}/${tag}/LICENSE"
license_sha=$(curl -fsSL "${license_url}" | sha256sum | awk '{print $1}')
echo "=> LICENSE sha256: ${license_sha}"

# 读取当前 PKGBUILD 中的两个 sha256
old_deb_sha=$(grep -oE '[a-f0-9]{64}' "${pkgbuild}" | sed -n '1p')
old_license_sha=$(grep -oE '[a-f0-9]{64}' "${pkgbuild}" | sed -n '2p')

echo '=> 更新 PKGBUILD...'
sed -i "s/^pkgver=.*/pkgver=${version}/" "${pkgbuild}"
sed -i "s/^pkgrel=.*/pkgrel=1/" "${pkgbuild}"
sed -i "s/${old_deb_sha}/${deb_sha}/" "${pkgbuild}"
sed -i "s/${old_license_sha}/${license_sha}/" "${pkgbuild}"

echo '=> 完成。请检查 diff，再从仓库根目录生成元数据、检查和构建。'
git diff "${pkgbuild}"
