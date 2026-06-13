#!/bin/bash
set -euo pipefail
ISO=${1:?Usage: write-usb.sh ISO /dev/sdX}
TARGET=${2:?Usage: write-usb.sh ISO /dev/sdX}
[ -f "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 1; }
[ -b "$TARGET" ] || { echo "Target block device not found: $TARGET" >&2; exit 1; }
RM=$(lsblk -dn -o RM "$TARGET")
TRAN=$(lsblk -dn -o TRAN "$TARGET")
TYPE=$(lsblk -dn -o TYPE "$TARGET")
if [ "$RM" != "1" ] || [ "$TYPE" != "disk" ]; then
  echo "Refusing: $TARGET is not a removable disk (RM=$RM TYPE=$TYPE TRAN=$TRAN)" >&2
  exit 1
fi
lsblk -o NAME,PATH,SIZE,MODEL,VENDOR,TRAN,RM,RO,TYPE,MOUNTPOINTS,FSTYPE,LABEL "$TARGET"
read -r -p "Type OVERWRITE to write $ISO to $TARGET: " ans
[ "$ans" = "OVERWRITE" ] || { echo "Aborted"; exit 1; }
for p in "${TARGET}"?*; do sudo umount "$p" 2>/dev/null || true; done
sudo dd if="$ISO" of="$TARGET" bs=16M status=progress conv=fsync
sync
sudo partprobe "$TARGET" 2>/dev/null || true
lsblk -o NAME,PATH,SIZE,MODEL,VENDOR,TRAN,RM,RO,TYPE,MOUNTPOINTS,FSTYPE,LABEL "$TARGET"
