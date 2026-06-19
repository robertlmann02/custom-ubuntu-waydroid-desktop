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

add_secure_boot_efi_support() {
  local output_iso="out/custom-ubuntu-waydroid-desktop-amd64.iso"
  local efi_img="binary/boot/grub/efi.img"
  local grub_cfg
  local shim_efi
  local grub_efi
  local mok_efi

  if [ ! -d binary ] || [ ! -f binary/isolinux/isolinux.bin ] || [ ! -f binary/live/vmlinuz ] || [ ! -f binary/live/initrd.img ]; then
    echo "Skipping UEFI/Secure Boot post-processing: live-build binary tree is incomplete" >&2
    return 1
  fi

  shim_efi="/usr/lib/shim/shimx64.efi.signed.latest"
  [ -f "$shim_efi" ] || shim_efi="/usr/lib/shim/shimx64.efi"
  grub_efi="/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed"
  mok_efi="/usr/lib/shim/mmx64.efi"
  for required in "$shim_efi" "$grub_efi" "$mok_efi" /usr/lib/ISOLINUX/isohdpfx.bin; do
    [ -f "$required" ] || { echo "Missing Secure Boot/ISO support file: $required" >&2; return 1; }
  done

  sudo mkdir -p binary/boot/grub
  sudo rm -f "$efi_img"
  sudo python3 - "$efi_img" <<'PYEOF'
import sys
with open(sys.argv[1], 'wb') as f:
    f.truncate(32 * 1024 * 1024)
PYEOF
  sudo mformat -i "$efi_img" -F -v CUSTOM_UBUNTU ::
  sudo mmd -i "$efi_img" ::/EFI ::/EFI/BOOT ::/EFI/ubuntu ::/boot ::/boot/grub

  sudo mcopy -i "$efi_img" "$shim_efi" ::/EFI/BOOT/BOOTX64.EFI
  sudo mcopy -i "$efi_img" "$grub_efi" ::/EFI/BOOT/grubx64.efi
  sudo mcopy -i "$efi_img" "$mok_efi" ::/EFI/BOOT/mmx64.efi

  # Also expose the removable-media EFI path in the ISO filesystem. Some
  # firmware can boot the El Torito EFI image directly, while other USB boot
  # pickers expect /EFI/BOOT/BOOTX64.EFI to be visible in the filesystem.
  sudo mkdir -p binary/EFI/BOOT binary/EFI/ubuntu
  sudo install -m 0644 "$shim_efi" binary/EFI/BOOT/BOOTX64.EFI
  sudo install -m 0644 "$grub_efi" binary/EFI/BOOT/grubx64.efi
  sudo install -m 0644 "$mok_efi" binary/EFI/BOOT/mmx64.efi

  grub_cfg=$(mktemp)
  cat > "$grub_cfg" <<'EOF'
search --no-floppy --set=root --label CUSTOM_UBUNTU
set default=0
set timeout=5

menuentry "Try Custom Ubuntu Desktop" {
    linux /live/vmlinuz boot=live config quiet splash
    initrd /live/initrd.img
}

menuentry "Try Custom Ubuntu Desktop (safe graphics)" {
    linux /live/vmlinuz boot=live config nomodeset noapic noapm nodma nomce nolapic nosmp nosplash vga=normal
    initrd /live/initrd.img
}
EOF
  sudo mcopy -i "$efi_img" "$grub_cfg" ::/EFI/ubuntu/grub.cfg
  sudo mcopy -i "$efi_img" "$grub_cfg" ::/EFI/BOOT/grub.cfg
  sudo mcopy -i "$efi_img" "$grub_cfg" ::/boot/grub/grub.cfg
  sudo install -m 0644 "$grub_cfg" binary/EFI/ubuntu/grub.cfg
  sudo install -m 0644 "$grub_cfg" binary/EFI/BOOT/grub.cfg
  rm -f "$grub_cfg"

  sudo xorriso -as mkisofs     -r -J -joliet-long -l -cache-inodes -allow-multidot     -V "CUSTOM_UBUNTU"     -A "Custom Ubuntu Waydroid Desktop"     -publisher "Custom Ubuntu Waydroid Desktop"     -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin     -partition_offset 16     -b isolinux/isolinux.bin       -c isolinux/boot.cat       -no-emul-boot -boot-load-size 4 -boot-info-table     -eltorito-alt-boot     -e boot/grub/efi.img       -no-emul-boot -isohybrid-gpt-basdat     -o "$output_iso"     binary
}

add_secure_boot_efi_support
sudo chown "$(id -u):$(id -g)" out/custom-ubuntu-waydroid-desktop-amd64.iso
sha256sum out/custom-ubuntu-waydroid-desktop-amd64.iso | tee out/custom-ubuntu-waydroid-desktop-amd64.iso.sha256
