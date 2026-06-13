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
sudo lb build 2>&1 | tee out/build.log
ISO=$(ls -1t live-image-amd64.hybrid.iso 2>/dev/null | head -1)
if [ -z "${ISO:-}" ]; then
  echo "No ISO produced" >&2
  exit 1
fi
cp -f "$ISO" out/custom-ubuntu-waydroid-desktop-amd64.iso
sha256sum out/custom-ubuntu-waydroid-desktop-amd64.iso | tee out/custom-ubuntu-waydroid-desktop-amd64.iso.sha256
