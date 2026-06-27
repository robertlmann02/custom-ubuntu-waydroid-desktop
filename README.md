# Custom Ubuntu Waydroid Desktop

<p align="center">
  <img src=".github/assets/mannindustries-logo.png" alt="MannIndustries logo" width="420">
</p>

A beginner-friendly Linux desktop ISO for people who are new to Linux but still want a system that feels polished, fast, familiar, and exciting from the first boot. It keeps the strength of Ubuntu underneath, removes common desktop distractions, and presents a ready-to-use desktop with a Windows-like bottom panel, a real Menu button, beautiful custom wallpapers, and practical everyday apps already in place.

## Why new Linux users will want it

- **Feels familiar immediately:** bottom taskbar, flush-left Menu button, app indicators, and a clean dark desktop layout.
- **Looks custom, not stock:** ships the custom MI Linux wallpaper collection only; Ubuntu/GNOME stock wallpapers are removed.
- **Ready for daily use:** Google Chrome, Microsoft Edge, Geary Mail, Rhythmbox Music, Steam, ONLYOFFICE, Wine, Winetricks, and Flatpak support are included.
- **No Snap clutter:** `snapd` and the GNOME Software Snap plugin are pinned out by policy.
- **Safer by default:** ClamAV/ClamTK antivirus plus rkhunter/chkrootkit rootkit scanning are included with low-priority automatic timers.
- **Android app path included:** Waydroid is preinstalled for users who want to explore Android app support on Linux.
- **Waydroid-compatible 7.1.1 kernel:** the build creates a custom `7.1.1-070101-waydroid-070101-waydroid` kernel with Android binder support enabled, matching the kernel tested successfully on the source desktop.
- **Bootable on modern PCs:** hybrid BIOS plus UEFI-capable USB media using Ubuntu shim/GRUB.

The look is built around a dark Zorin-inspired GNOME experience: Zorin Blue Dark GTK and icon themes, a bottom panel, ArcMenu-style application launcher, app indicators, and subtle shell effects for a familiar Windows-like desktop layout while keeping the Ubuntu base. This wallpaper release ships the custom MI Linux wallpaper collection only, removes Ubuntu/GNOME stock wallpapers from the live image, and defaults to the Linux Vanguard wallpaper used on the source desktop.

## Build

On an Ubuntu host with sudo:

```bash
sudo apt-get update
sudo apt-get install -y live-build isolinux syslinux-utils grub-pc-bin grub-efi-amd64-signed shim-signed xorriso squashfs-tools debootstrap mtools dosfstools curl jq git build-essential bc bison flex libssl-dev libelf-dev libdw-dev dwarves debhelper fakeroot xz-utils sbsigntool
./scripts/build-iso.sh
```

Output ISO is written under `out/`.

The first build also compiles the custom Waydroid kernel from kernel.org source using `config/kernel/7.1.1-070101-generic.config` as the base config. Built `.deb` packages are stored under `local/kernel-debs/` and are intentionally ignored by git.

## Boot compatibility

`scripts/build-iso.sh` post-processes the live-build ISO into hybrid USB media with:

- Legacy BIOS/CSM boot through ISOLINUX
- UEFI removable-media boot path at `/EFI/BOOT/BOOTX64.EFI`
- Signed Ubuntu shim and signed GRUB EFI loader for UEFI/Secure Boot-enabled machines
- The live image kernel loaded by GRUB; the custom Waydroid 7.1.1 kernel is signed locally during the build when the generated MOK key is present

Secure Boot still depends on the target firmware trusting the standard Microsoft/Canonical Secure Boot chain and, for the custom Waydroid kernel, the user enrolling the generated public MOK certificate included on the ISO.

## Write to USB

Use `lsblk` to identify the removable USB disk, then:

```bash
sudo ./scripts/write-usb.sh out/custom-ubuntu-waydroid-desktop-amd64.iso /dev/sdX
```

**Warning:** this overwrites the target disk.

## Branding and defaults

The build recipe includes the current MI PC boot branding assets under:

```text
config/includes.chroot/usr/local/share/custom-boot-branding/
```

The desktop hook installs those assets as a Plymouth theme and GRUB background, installs the bundled MannIndustries wallpaper set under `/usr/share/backgrounds/mannindustries/`, removes stock Ubuntu/GNOME wallpaper payloads and metadata, publishes a custom wallpaper picker XML for the bundled set, defaults both desktop and lock-screen wallpaper to `mi_linux_12_linux_vanguard_1920x1080.jpg`, sets Geary as the default mail handler, sets Rhythmbox as the default music player, and applies GNOME shell defaults for the bottom Zorin-style taskbar/start-menu workflow, including the flush-left Menu button and hidden Show Apps slot. Replace the bundled boot images or wallpaper assets before building if you need different organization-specific branding.

## Malware and rootkit protection

The ISO recipe includes Snap-free, apt-based malware protection matching the source desktop pattern:

- ClamAV engine, daemon, and freshclam signature updates
- ClamTK GUI for manual scans
- rkhunter and chkrootkit for rootkit checks
- `/usr/local/sbin/custom-security-scan` helper with `quick`, `full`, `rootkit`, and `smoke` modes
- Daily quick scan timer at 03:30, weekly full scan timer at Sunday 04:30, and weekly rootkit timer at Sunday 05:30
- Logs under `/var/log/custom-security/` and quarantine under `/var/quarantine/custom-security/`

The scan helper runs with low CPU/I/O priority and excludes common cache and Steam library paths to reduce desktop/gaming impact.

## Optional custom Secure Boot kernel signing

The recipe uses a custom 7.1.1 Waydroid kernel, so Secure Boot requires local Machine Owner Key (MOK) signing. `scripts/build-iso.sh` will generate local MOK key material if it is missing, keep the private key outside git, sign the live kernel during ISO post-processing, and copy the public `.cer` into the ISO for enrollment on target PCs.

```bash
./scripts/generate-secure-boot-key.sh
./scripts/build-iso.sh
```

By default the build script looks for:

```text
local/secure-boot/custom-secure-boot.key
local/secure-boot/custom-secure-boot.crt
local/secure-boot/custom-secure-boot.cer
```

For this custom kernel build, `scripts/build-iso.sh` signs `binary/live/vmlinuz`, verifies the signature with `sbverify`, and copies the public enrollment certificate into the ISO at:

```text
/secure-boot/custom-secure-boot.cer
/EFI/BOOT/custom-secure-boot.cer
```

Keep `custom-secure-boot.key` private. New users only need the public `.cer` file during the one-time MOK enrollment flow on Secure Boot PCs.
