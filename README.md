# Custom Ubuntu Waydroid Desktop

<p align="center">
  <img src=".github/assets/mannindustries-logo.png" alt="MannIndustries logo" width="420">
</p>


A reproducible Ubuntu-based live desktop image configured like the source GNOME workstation:

- Snap-free by policy (`snapd` and GNOME Software Snap plugin are pinned out)
- GNOME desktop with Zorin-style themes/icons and bottom-panel/start-menu workflow
- Waydroid preinstalled
- Google Chrome as the default browser
- Microsoft Edge preinstalled
- Geary Mail as the default mail app (`mailto:` and message files)
- Rhythmbox Music as the default music app for common audio files
- ClamAV/ClamTK antivirus plus rkhunter/chkrootkit rootkit scanning, with automatic low-priority timers
- Steam and ONLYOFFICE Desktop Editors prepackaged
- GNOME Tweaks and shell extension preferences included for post-install desktop tuning
- MI PC boot logo assets and Plymouth/GRUB boot branding support
- Hybrid BIOS plus UEFI Secure Boot-capable USB boot media using signed Ubuntu shim/GRUB
- Wine, Winetricks, Flatpak, Bottles support for Windows apps
- GNOME Keyring installed with a blank default keyring password initialized at first login

The look is built around a dark Zorin-inspired GNOME experience: Zorin Blue Dark GTK and icon themes, a bottom panel, ArcMenu-style application launcher, app indicators, and subtle shell effects for a familiar Windows-like desktop layout while keeping the Ubuntu base.

## Build

On an Ubuntu host with sudo:

```bash
sudo apt-get update
sudo apt-get install -y live-build isolinux syslinux-utils grub-pc-bin grub-efi-amd64-signed shim-signed xorriso squashfs-tools debootstrap mtools dosfstools curl jq git
./scripts/build-iso.sh
```

Output ISO is written under `out/`.


## Boot compatibility

`scripts/build-iso.sh` post-processes the live-build ISO into hybrid USB media with:

- Legacy BIOS/CSM boot through ISOLINUX
- UEFI removable-media boot path at `/EFI/BOOT/BOOTX64.EFI`
- Signed Ubuntu shim and signed GRUB EFI loader for Secure Boot-enabled machines
- The signed Ubuntu kernel from the live image loaded by GRUB

Secure Boot still depends on the target firmware trusting the standard Microsoft/Canonical Secure Boot chain.

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

The desktop hook installs those assets as a Plymouth theme and GRUB background, sets Geary as the default mail handler, sets Rhythmbox as the default music player, and applies GNOME shell defaults for the bottom Zorin-style taskbar/start-menu workflow, including the flush-left Menu button and hidden Show Apps slot. Replace the bundled boot images before building if you need different organization-specific branding.

## Malware and rootkit protection

The ISO recipe includes Snap-free, apt-based malware protection matching the source desktop pattern:

- ClamAV engine, daemon, and freshclam signature updates
- ClamTK GUI for manual scans
- rkhunter and chkrootkit for rootkit checks
- `/usr/local/sbin/custom-security-scan` helper with `quick`, `full`, `rootkit`, and `smoke` modes
- Daily quick scan timer at 03:30, weekly full scan timer at Sunday 04:30, and weekly rootkit timer at Sunday 05:30
- Logs under `/var/log/custom-security/` and quarantine under `/var/quarantine/custom-security/`

The scan helper runs with low CPU/I/O priority and excludes common cache and Steam library paths to reduce desktop/gaming impact.
