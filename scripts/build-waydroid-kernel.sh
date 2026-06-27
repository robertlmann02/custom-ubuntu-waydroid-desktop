#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_ROOT=${BUILD_ROOT:-"$ROOT/local/kernel-build"}
OUT_DIR=${OUT_DIR:-"$ROOT/local/kernel-debs"}
KVER=${KVER:-7.1.1}
UBUNTU_MAINLINE=${UBUNTU_MAINLINE:-070101}
PKG_VERSION=${PKG_VERSION:-7.1.1-070101.waydroid1}
LOCAL_FLAVOR=${LOCAL_FLAVOR:-070101-waydroid}
SRC_DIR="$BUILD_ROOT/linux-$KVER-waydroid"
TARBALL="$BUILD_ROOT/linux-$KVER.tar.xz"
BASE_CONFIG="$ROOT/config/kernel/7.1.1-070101-generic.config"
LOG="$BUILD_ROOT/build-waydroid-$KVER.log"

mkdir -p "$BUILD_ROOT" "$OUT_DIR"
exec > >(tee -a "$LOG") 2>&1

echo "== start $(date -Is) =="
echo "host=$(hostname) kernel=$(uname -r) nproc=$(nproc)"

missing=()
for cmd in curl tar make gcc flex bison openssl dpkg-buildpackage; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing build commands: ${missing[*]}" >&2
  echo "Install build deps with:" >&2
  echo "sudo apt-get install -y build-essential bc bison flex libssl-dev libelf-dev libdw-dev dwarves debhelper fakeroot curl xz-utils" >&2
  exit 1
fi

if [ ! -s "$BASE_CONFIG" ]; then
  echo "Missing base kernel config: $BASE_CONFIG" >&2
  exit 1
fi

if [ ! -s "$TARBALL" ]; then
  echo "== downloading kernel.org linux-$KVER =="
  curl -fL --retry 3 --retry-delay 5 "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$KVER.tar.xz" -o "$TARBALL"
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "== extracting source =="
  rm -rf "$BUILD_ROOT/linux-$KVER" "$SRC_DIR"
  tar -xf "$TARBALL" -C "$BUILD_ROOT"
  mv "$BUILD_ROOT/linux-$KVER" "$SRC_DIR"
fi

cd "$SRC_DIR"
echo "== configure Waydroid-capable 7.1.1 kernel =="
cp "$BASE_CONFIG" .config
./scripts/config --set-str LOCALVERSION "-$LOCAL_FLAVOR"
./scripts/config --disable LOCALVERSION_AUTO
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --set-str SYSTEM_REVOCATION_KEYS ""
./scripts/config --disable DEBUG_INFO
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5
./scripts/config --disable DEBUG_INFO_BTF
./scripts/config --disable DEBUG_INFO_BTF_MODULES
./scripts/config --enable ANDROID_BINDER_IPC
./scripts/config --enable ANDROID_BINDERFS
./scripts/config --set-str ANDROID_BINDER_DEVICES "anbox-binder,anbox-hwbinder,anbox-vndbinder,binder,hwbinder,vndbinder"
./scripts/config --disable MODULE_SIG_ALL
make olddefconfig

echo "== binder config after olddefconfig =="
grep -E 'CONFIG_ANDROID_BINDER|CONFIG_ANDROID_BINDERFS|CONFIG_ANDROID_BINDER_DEVICES|CONFIG_LOCALVERSION|CONFIG_SYSTEM_TRUSTED_KEYS|CONFIG_SYSTEM_REVOCATION_KEYS|CONFIG_MODULE_SIG_ALL' .config || true
test "$(./scripts/config --state ANDROID_BINDER_IPC)" = "y"
test "$(./scripts/config --state ANDROID_BINDERFS)" = "y"

rm -f "$BUILD_ROOT"/*waydroid*.deb "$BUILD_ROOT"/linux-libc-dev_*waydroid*.deb "$BUILD_ROOT"/linux-upstream_*waydroid*.buildinfo "$BUILD_ROOT"/linux-upstream_*waydroid*.changes

echo "== build Debian kernel packages =="
export KDEB_CHANGELOG_DIST=resolute
make -j"$(nproc)" bindeb-pkg KDEB_PKGVERSION="$PKG_VERSION" LOCALVERSION="-$LOCAL_FLAVOR"

install -m 0644 "$BUILD_ROOT"/linux-image-*waydroid*.deb "$OUT_DIR"/
install -m 0644 "$BUILD_ROOT"/linux-headers-*waydroid*.deb "$OUT_DIR"/
install -m 0644 "$BUILD_ROOT"/linux-libc-dev_*waydroid*.deb "$OUT_DIR"/ 2>/dev/null || true

echo "== built packages copied to $OUT_DIR =="
ls -lh "$OUT_DIR"/*.deb
sha256sum "$OUT_DIR"/*.deb | tee "$OUT_DIR/SHA256SUMS"
echo "== done $(date -Is) =="
