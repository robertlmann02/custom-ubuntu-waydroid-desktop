#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
mkdir -p out
sudo lb clean --purge || true
lb config \
  --mode ubuntu \
  --distribution resolute \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootloader syslinux \
  --syslinux-theme live-build \
  --initramfs live-boot \
  --initsystem systemd \
  --archive-areas "main restricted universe multiverse" \
  --parent-mirror-bootstrap http://archive.ubuntu.com/ubuntu/ \
  --parent-mirror-chroot http://archive.ubuntu.com/ubuntu/ \
  --parent-mirror-binary http://archive.ubuntu.com/ubuntu/ \
  --mirror-bootstrap http://archive.ubuntu.com/ubuntu/ \
  --mirror-chroot http://archive.ubuntu.com/ubuntu/ \
  --mirror-binary http://archive.ubuntu.com/ubuntu/ \
  --security false \
  --apt-recommends true \
  --memtest none \
  --iso-application "Custom Ubuntu Waydroid Desktop" \
  --iso-publisher "Custom Ubuntu Waydroid Desktop" \
  --iso-volume "CUSTOM_UBUNTU" \
  --source false \
  --checksums sha256
set +e
sudo lb build 2>&1 | tee out/build.log
build_status=${PIPESTATUS[0]}
set -e
ISO=$(find . -maxdepth 1 -type f \( -name 'live-image-amd64.hybrid.iso' -o -name 'binary.hybrid.iso' \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {print $2}')
if [ "$build_status" -ne 0 ] && [ -z "${ISO:-}" ]; then
  echo "live-build failed before producing an ISO" >&2
  exit "$build_status"
fi
if [ -z "${ISO:-}" ]; then
  echo "No ISO produced" >&2
  exit 1
fi
sudo cp -f "$ISO" out/custom-ubuntu-waydroid-desktop-amd64.iso
sudo chown "$(id -u):$(id -g)" out/custom-ubuntu-waydroid-desktop-amd64.iso
sha256sum out/custom-ubuntu-waydroid-desktop-amd64.iso | tee out/custom-ubuntu-waydroid-desktop-amd64.iso.sha256
