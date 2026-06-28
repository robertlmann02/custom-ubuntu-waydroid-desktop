# Create a bootable USB from GitHub

This repository supports three practical paths:

1. **GitHub-only build path:** run the repository's GitHub Actions workflow, download the `bootable-iso-parts` artifact, reassemble/verify it with the helper script, then write the USB.
2. **Local builder path:** rebuild the ISO from source on an Ubuntu build environment, then write it to USB.
3. **Published release path:** if a release publishes split ISO parts, download/reassemble/verify those parts with the same helper script.

The USB write step overwrites the whole USB disk. Back up anything on that stick first.

## What you need

- A 16 GB or larger USB stick.
- Python 3.9 or newer.
- Administrator rights for the final USB write step.
- This GitHub repository cloned or downloaded as a ZIP.

## Path 1: build from GitHub Actions

This is the most OS-independent path because GitHub does the Linux ISO build.

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Choose **Build bootable ISO**.
4. Click **Run workflow** on `main`.
5. When it finishes, download the `bootable-iso-parts` artifact.
6. Unzip the artifact. It contains files like:

```text
custom-ubuntu-waydroid-desktop-amd64.iso.part01
custom-ubuntu-waydroid-desktop-amd64.iso.part02
custom-ubuntu-waydroid-desktop-amd64.iso.part03
...more parts when needed
custom-ubuntu-waydroid-desktop-amd64.iso.sha256
```

Then use the commands below for your OS.

## Windows

Open **PowerShell as Administrator**:

```powershell
git clone https://github.com/robertlmann02/custom-ubuntu-waydroid-desktop.git
cd custom-ubuntu-waydroid-desktop
py -3 scripts\usb_boot_media.py --list
```

Find the USB disk number, then write it from the unzipped artifact directory. Example for disk `3`:

```powershell
py -3 scripts\usb_boot_media.py --parts-dir C:\Users\YOU\Downloads\bootable-iso-parts --target 3
```

Type `OVERWRITE` only after confirming the disk number is the USB stick.

If you prefer a graphical USB writer, run only the reassemble/verify step:

```powershell
py -3 scripts\usb_boot_media.py --parts-dir C:\Users\YOU\Downloads\bootable-iso-parts
```

Then write `custom-ubuntu-waydroid-desktop-amd64.iso` with Rufus or balenaEtcher.

## macOS

Open Terminal:

```bash
git clone https://github.com/robertlmann02/custom-ubuntu-waydroid-desktop.git
cd custom-ubuntu-waydroid-desktop
python3 scripts/usb_boot_media.py --list
```

Find the USB disk, usually `/dev/diskN`, then write it:

```bash
sudo python3 scripts/usb_boot_media.py --parts-dir ~/Downloads/bootable-iso-parts --target /dev/diskN
```

Type `OVERWRITE` only after confirming `/dev/diskN` is the USB stick.

If you prefer a graphical USB writer:

```bash
python3 scripts/usb_boot_media.py --parts-dir ~/Downloads/bootable-iso-parts
```

Then write `custom-ubuntu-waydroid-desktop-amd64.iso` with balenaEtcher.

## Linux

Open a terminal:

```bash
git clone https://github.com/robertlmann02/custom-ubuntu-waydroid-desktop.git
cd custom-ubuntu-waydroid-desktop
python3 scripts/usb_boot_media.py --list
```

Find the removable USB disk, usually `/dev/sdX`, then write it:

```bash
sudo python3 scripts/usb_boot_media.py --parts-dir ~/Downloads/bootable-iso-parts --target /dev/sdX
```

The Linux path refuses non-removable disks when `lsblk` reports the target is not removable.

If you already built or downloaded the ISO yourself:

```bash
sudo python3 scripts/usb_boot_media.py --iso out/custom-ubuntu-waydroid-desktop-amd64.iso --target /dev/sdX
```

## Optional release path

If this repository publishes a release with split ISO assets, the helper can download that release directly:

```bash
python3 scripts/usb_boot_media.py --release latest
python3 scripts/usb_boot_media.py --release latest --target <USB_DISK>
```

Use the GitHub Actions artifact path when no release is published.

## Build the ISO yourself

The build recipe is Linux/live-build based. If your daily computer is Windows or macOS, build inside one of these:

- Ubuntu 26.04 installed on a spare machine.
- Ubuntu in a VM.
- WSL2 Ubuntu on Windows with enough disk space, then write the finished ISO with Rufus/balenaEtcher from Windows.

On Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y live-build isolinux syslinux-utils grub-pc-bin grub-efi-amd64-signed shim-signed xorriso squashfs-tools debootstrap mtools dosfstools curl jq git build-essential bc bison flex libssl-dev libelf-dev libdw-dev dwarves debhelper fakeroot xz-utils sbsigntool
./scripts/build-iso.sh
sha256sum -c out/custom-ubuntu-waydroid-desktop-amd64.iso.sha256
```

Then write:

```bash
sudo ./scripts/write-usb.sh out/custom-ubuntu-waydroid-desktop-amd64.iso /dev/sdX
```

## Secure Boot note

This image uses a custom Waydroid-capable kernel. On Secure Boot PCs, enroll the public MOK certificate included on the USB when prompted. The private signing key is not in git and is not needed by normal USB users.

## Safety checklist

Before writing:

- Confirm the target is the USB stick, not an internal SSD/NVMe drive.
- Confirm the USB is 16 GB or larger.
- Confirm you typed the whole disk, not a partition.
  - Good: `/dev/sdX`, `/dev/diskN`, Windows disk number `3`.
  - Wrong: `/dev/sdX1`, `/dev/diskNs1`, `C:`.
- Expect all existing data on the USB stick to be erased.
