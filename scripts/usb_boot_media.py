#!/usr/bin/env python3
"""Create a bootable USB from the published ISO release chunks or a local ISO.

Works with Python 3.9+ on Windows, macOS, and Linux. It intentionally requires
an explicit whole-disk target and a typed confirmation before overwriting media.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO = "robertlmann02/custom-ubuntu-waydroid-desktop"
ISO_NAME = "custom-ubuntu-waydroid-desktop-amd64.iso"
CHUNK_PATTERN = re.compile(rf"^{re.escape(ISO_NAME)}\.part(\d+)$")


def run(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=check, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024 * 8), b""):
            h.update(block)
    return h.hexdigest()


def github_api(url: str) -> dict:
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json", "User-Agent": "custom-ubuntu-usb-helper"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".tmp")
    print(f"Downloading {dest.name}...")
    req = urllib.request.Request(url, headers={"User-Agent": "custom-ubuntu-usb-helper"})
    with urllib.request.urlopen(req) as resp, tmp.open("wb") as out:
        shutil.copyfileobj(resp, out, length=1024 * 1024 * 8)
    tmp.replace(dest)


def chunk_number(name: str) -> int:
    match = CHUNK_PATTERN.match(name)
    if not match:
        raise ValueError(name)
    return int(match.group(1))


def assemble_parts(parts_dir: Path) -> Path:
    sha_name = ISO_NAME + ".sha256"
    chunk_names = sorted((p.name for p in parts_dir.iterdir() if CHUNK_PATTERN.match(p.name)), key=chunk_number)
    if not chunk_names:
        raise SystemExit(f"No split ISO chunks found in {parts_dir}; expected {ISO_NAME}.partNN")
    if not (parts_dir / sha_name).is_file():
        raise SystemExit(f"Missing checksum file in {parts_dir}: {sha_name}")

    iso = parts_dir / ISO_NAME
    print(f"Reassembling {iso.name} from {len(chunk_names)} chunks...")
    with iso.open("wb") as out:
        for name in chunk_names:
            with (parts_dir / name).open("rb") as part:
                shutil.copyfileobj(part, out, length=1024 * 1024 * 8)

    expected_text = (parts_dir / sha_name).read_text(encoding="utf-8", errors="replace")
    expected = expected_text.split()[0].lower()
    actual = sha256(iso)
    if actual != expected:
        raise SystemExit(f"Checksum FAILED for {iso}: expected {expected}, got {actual}")
    print(f"Checksum OK: {actual}")
    return iso


def download_release(tag: str, out_dir: Path) -> Path:
    api = f"https://api.github.com/repos/{REPO}/releases/"
    release = github_api(api + ("latest" if tag == "latest" else f"tags/{tag}"))
    assets = release.get("assets", [])
    by_name = {a["name"]: a for a in assets}
    sha_name = ISO_NAME + ".sha256"
    needed = sorted((name for name in by_name if CHUNK_PATTERN.match(name)), key=chunk_number) + [sha_name]
    if sha_name not in by_name or len(needed) == 1:
        raise SystemExit(f"Release {release.get('tag_name')} does not contain the split ISO chunks and {sha_name}")

    for name in needed:
        dest = out_dir / name
        if not dest.exists():
            download(by_name[name]["browser_download_url"], dest)
    return assemble_parts(out_dir)


def list_targets() -> None:
    system = platform.system()
    if system == "Linux":
        cmd = ["lsblk", "-o", "NAME,PATH,SIZE,MODEL,VENDOR,TRAN,RM,RO,TYPE,MOUNTPOINTS,FSTYPE,LABEL"]
    elif system == "Darwin":
        cmd = ["diskutil", "list"]
    elif system == "Windows":
        cmd = ["powershell", "-NoProfile", "-Command", "Get-Disk | Format-Table -Auto Number,FriendlyName,BusType,Size,OperationalStatus,IsBoot,IsSystem"]
    else:
        raise SystemExit(f"Unsupported OS: {system}")
    print(run(cmd, check=False).stdout)


def validate_linux(target: str) -> None:
    info = run(["lsblk", "-J", "-dn", "-o", "PATH,RM,RO,TYPE", target]).stdout
    data = json.loads(info).get("blockdevices", [])
    if not data:
        raise SystemExit(f"Target not found: {target}")
    d = data[0]
    rm = d.get("rm")
    ro = d.get("ro")
    removable = rm is True or str(rm) == "1"
    readonly = ro is True or str(ro) == "1"
    if d.get("type") != "disk" or not removable or readonly:
        raise SystemExit(f"Refusing {target}: target must be a writable removable whole disk")


def unmount_target(target: str) -> None:
    system = platform.system()
    if system == "Linux":
        parts = run(["lsblk", "-ln", "-o", "PATH", target], check=False).stdout.splitlines()[1:]
        for part in parts:
            subprocess.run(["sudo", "umount", part], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif system == "Darwin":
        run(["diskutil", "unmountDisk", target])
    elif system == "Windows":
        m = re.fullmatch(r"(?:\\\\\.\\PhysicalDrive)?(\d+)", target)
        if not m:
            raise SystemExit("Windows target must be a disk number like 3 or \\\\.\\PhysicalDrive3")
        disk = m.group(1)
        ps = f"Get-Disk -Number {disk} | Set-Disk -IsOffline $true; Get-Disk -Number {disk} | Set-Disk -IsReadOnly $false"
        run(["powershell", "-NoProfile", "-Command", ps], check=False)


def open_target_for_write(target: str):
    system = platform.system()
    if system == "Windows":
        m = re.fullmatch(r"(?:\\\\\.\\PhysicalDrive)?(\d+)", target)
        if not m:
            raise SystemExit("Windows target must be a disk number like 3 or \\\\.\\PhysicalDrive3")
        return open(rf"\\.\PhysicalDrive{m.group(1)}", "r+b", buffering=0)
    if system == "Darwin" and target.startswith("/dev/disk"):
        target = target.replace("/dev/disk", "/dev/rdisk", 1)
    return open(target, "wb", buffering=0)


def write_usb(iso: Path, target: str, yes: bool) -> None:
    system = platform.system()
    if system == "Linux":
        validate_linux(target)
    print("Detected targets:")
    list_targets()
    if not yes:
        ans = input(f"Type OVERWRITE to write {iso} to {target}: ")
        if ans != "OVERWRITE":
            raise SystemExit("Aborted")
    unmount_target(target)
    size = iso.stat().st_size
    copied = 0
    started = time.time()
    print(f"Writing {size} bytes to {target}...")
    with iso.open("rb") as src, open_target_for_write(target) as dst:
        for block in iter(lambda: src.read(1024 * 1024 * 8), b""):
            dst.write(block)
            copied += len(block)
            if copied % (1024 * 1024 * 256) < len(block):
                pct = copied * 100 / size
                print(f"  {pct:5.1f}%", flush=True)
        try:
            dst.flush()
            os.fsync(dst.fileno())
        except OSError:
            pass
    print(f"Write complete in {time.time() - started:.0f}s")
    print("Re-listing targets after write:")
    list_targets()


def main() -> int:
    p = argparse.ArgumentParser(description="Download/reassemble the GitHub release ISO and write a bootable USB.")
    p.add_argument("--release", help="GitHub release tag to download, or latest")
    p.add_argument("--download-dir", default="downloads", help="Where release chunks and ISO are stored")
    p.add_argument("--parts-dir", help="Use an existing directory of ISO part files, such as a downloaded GitHub Actions artifact")
    p.add_argument("--iso", help="Use an existing local ISO instead of release/artifact chunks")
    p.add_argument("--target", help="Whole USB disk to overwrite, for example /dev/sdX, /dev/diskN, or Windows disk number")
    p.add_argument("--list", action="store_true", help="List likely USB targets and exit")
    p.add_argument("--yes", action="store_true", help="Skip the OVERWRITE prompt; still validates removable disks on Linux")
    args = p.parse_args()

    if args.list:
        list_targets()
        return 0
    iso: Path
    if args.iso:
        iso = Path(args.iso).expanduser().resolve()
    elif args.parts_dir:
        iso = assemble_parts(Path(args.parts_dir).expanduser().resolve())
    elif args.release:
        iso = download_release(args.release, Path(args.download_dir).expanduser().resolve())
    else:
        raise SystemExit("Choose one input: --iso, --parts-dir, or --release latest")
    if not iso.is_file():
        raise SystemExit(f"ISO not found: {iso}")
    print(f"ISO: {iso}")
    print(f"SHA256: {sha256(iso)}")
    if args.target:
        write_usb(iso, args.target, args.yes)
    else:
        print("No --target supplied, so nothing was overwritten. Use --list to inspect USB disks first.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
