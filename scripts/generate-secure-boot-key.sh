#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT_DIR=${1:-"$ROOT/local/secure-boot"}
mkdir -p "$OUT_DIR"
KEY="$OUT_DIR/custom-secure-boot.key"
CRT="$OUT_DIR/custom-secure-boot.crt"
CER="$OUT_DIR/custom-secure-boot.cer"
if [ -e "$KEY" ] || [ -e "$CRT" ] || [ -e "$CER" ]; then
  echo "Refusing to overwrite existing Secure Boot key material in $OUT_DIR" >&2
  exit 1
fi
openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes -days 3650 \
  -subj "/CN=Custom Ubuntu Waydroid Secure Boot/" \
  -keyout "$KEY" -out "$CRT"
openssl x509 -in "$CRT" -outform DER -out "$CER"
chmod 0600 "$KEY"
chmod 0644 "$CRT" "$CER"
echo "Created:"
echo "  private key: $KEY"
echo "  certificate: $CRT"
echo "  MOK enrollment cert: $CER"
echo
echo "Keep the .key private. Enroll the .cer through MokManager or mokutil on the target PC."
