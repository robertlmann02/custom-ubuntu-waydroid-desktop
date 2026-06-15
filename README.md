# Custom Ubuntu Waydroid Desktop

A reproducible Ubuntu-based live desktop image configured like the source GNOME workstation:

- Snap-free by policy (`snapd` and GNOME Software Snap plugin are pinned out)
- GNOME desktop with Zorin-style themes/icons and bottom-panel/start-menu workflow
- Waydroid preinstalled
- Google Chrome as the default browser
- Microsoft Edge preinstalled
- Geary Mail as the default mail app (`mailto:` and message files)
- Steam and ONLYOFFICE Desktop Editors prepackaged
- Custom GNOME theme defaults with bottom panel/start menu, app indicators, and blur/transparency extensions
- Generic boot logo assets and Plymouth/GRUB boot branding support
- Wine, Winetricks, Flatpak, Bottles support for Windows apps
- GNOME Keyring installed with a blank default keyring password initialized at first login

The look is built around a dark Zorin-inspired GNOME experience: Zorin Blue Dark GTK and icon themes, a bottom panel, ArcMenu-style application launcher, app indicators, and subtle shell effects for a familiar Windows-like desktop layout while keeping the Ubuntu base.

## Build

On an Ubuntu host with sudo:

```bash
sudo apt-get update
sudo apt-get install -y live-build isolinux syslinux-utils grub-pc-bin xorriso squashfs-tools debootstrap mtools dosfstools curl jq git
./scripts/build-iso.sh
```

Output ISO is written under `out/`.

## Write to USB

Use `lsblk` to identify the removable USB disk, then:

```bash
sudo ./scripts/write-usb.sh out/custom-ubuntu-waydroid-desktop-amd64.iso /dev/sdX
```

**Warning:** this overwrites the target disk.

## Branding and defaults

The build recipe includes generic, public-safe boot branding assets under:

```text
config/includes.chroot/usr/local/share/custom-boot-branding/
```

The desktop hook installs those assets as a Plymouth theme and GRUB background, sets Geary as the default mail handler, and applies GNOME shell defaults for the bottom panel/start-menu workflow. Replace the generic boot images before building if you need organization-specific branding.
