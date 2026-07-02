#!/usr/bin/env bash
set -euo pipefail

# 自动获取 GitHub 最新 Release 并更新 PKGBUILD
# 用法: ./update-pkgbuild.sh [--force]
#
# 安全说明：
#   脚本会优先寻找 release 里附带的独立校验文件（*.sha256、SHA256SUMS、
#   checksums.txt 等）来验证下载的 .deb；如果没有找到，会提示风险并
#   要求人工确认，因为本地计算的 hash 不能保证二进制未被篡改。

repo='ProxyShard/ShardBrowser'
pkgbuild='PKGBUILD'
force=0

if [[ "${1:-}" == '--force' ]]; then
  force=1
fi

echo '=> 查询最新 release...'
release_json=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest")
tag=$(printf '%s' "$release_json" | jq -r '.tag_name')
version=${tag#v}

echo "=> 最新版本: ${version}"

debfile="ShardX.Launcher_${version}_amd64.deb"
deburl="https://github.com/${repo}/releases/download/${tag}/${debfile}"

echo '=> 下载 .deb...'
curl -fsSL -o "${debfile}" "${deburl}"

# 尝试寻找并验证上游独立校验文件
echo '=> 查找上游校验文件...'
mapfile -t checksum_assets < <(printf '%s' "$release_json" | jq -r '
  .assets[] |
  select(.name | test("sha(256|512)|checksum|sums"; "i")) |
  .name
')

verified=0
for asset in "${checksum_assets[@]}"; do
  case "${asset}" in
    *"${debfile}"*.sha256|*"${debfile}"*.sha512|SHA256SUMS|SHA512SUMS|checksums.txt|checksums.sha256|checksums.sha512)
      echo "   发现校验文件: ${asset}"
      curl -fsSL -o "${asset}" "https://github.com/${repo}/releases/download/${tag}/${asset}"
      if sha256sum --check --strict "${asset}" 2>/dev/null | grep -q "${debfile}: OK" || \
         sha512sum --check --strict "${asset}" 2>/dev/null | grep -q "${debfile}: OK"; then
        echo '   上游校验通过'
        verified=1
      else
        echo "!! 警告：${asset} 未能验证 ${debfile}" >&2
      fi
      rm -f "${asset}"
      ;;
  esac
done

if [[ "$verified" -eq 0 ]]; then
  echo '!! 上游 release 未提供该 .deb 的独立校验文件。' >&2
  echo '   本地计算的 hash 只能保证文件完整性，不能保证未被篡改。' >&2
  if [[ "$force" -eq 0 ]]; then
    echo -n '   是否仍要更新 PKGBUILD? [y/N] ' >&2
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { rm -f "${debfile}"; exit 1; }
  else
    echo '   --force 已设置，跳过确认。' >&2
  fi
fi

deb_sha=$(sha256sum "${debfile}" | awk '{print $1}')
rm -f "${debfile}"
echo "=> .deb sha256: ${deb_sha}"

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

echo '=> 完成。请检查 diff 后提交: makepkg -si'
git diff "${pkgbuild}"
