# Changelog

## Unreleased

- Update the ISO recipe to build and stage the hardware-tested custom `7.1.1-070101-waydroid-070101-waydroid` kernel with Android binder/binderfs support, plus local MOK Secure Boot signing for that custom kernel.
- Rename the ArcMenu/Menu taskbar label from `Menu` to `Linux` next to the MI emblem.
- Replace the ArcMenu/Menu taskbar icon with the MannIndustries MI shield/emblem artwork.
- Document that stock `7.1.1-070101-generic` is blocked because it lacks binder, while the custom 7.1.1 Waydroid flavor is used for future builds.
- Add a persistent Waydroid binder setup service that loads `binder_linux`, mounts binderfs, and creates the `/dev/anbox-*` device links Waydroid expects.
- Use local MOK Secure Boot signing for the custom 7.1.1 Waydroid kernel while keeping private key material out of git.
- Wallpaper release: add the 43-file custom MI Linux wallpaper collection, remove Ubuntu/GNOME stock wallpapers from the live image, set Linux Vanguard as the default desktop/lock-screen wallpaper, and refresh the GitHub wording for new Linux users who want a polished first-boot experience.
- Add UEFI Secure Boot-capable USB boot support with signed Ubuntu shim/GRUB, visible `/EFI/BOOT/BOOTX64.EFI`, and an El Torito EFI system partition while preserving legacy ISOLINUX boot.
- Add ClamAV/ClamTK malware protection plus rkhunter/chkrootkit rootkit scanning to the ISO recipe, with automatic low-priority quick/full/rootkit scan timers and quarantine/log paths.
- Add Rhythmbox Music as the default music player for common audio file types.
- Refresh the bundled boot artwork to the latest MI PC no-square radial-glow logo used by the current desktop builds.
- Update installed desktop defaults to match the latest source-desktop taskbar: bottom Zorin-blue panel, 48px height, flush-left Menu button, and no reserved Show Apps gap.
- Fix boot-branding hook newline handling and preserve a produced hybrid ISO when live-build exits nonzero during the source stage.
- Switch the bundled boot logo artwork to the current MI PC desktop mark used by the ISO branding.
- Add Geary Mail as the default mail handler for `mailto:` links and RFC 822 message files.
- Prepackage Steam and ONLYOFFICE Desktop Editors in the custom desktop build.
- Bake in GNOME theme defaults for bottom panel/start-menu workflow, app indicators, blur, and transparency.
- Add generic boot-logo assets plus Plymouth and GRUB boot-branding setup.
- Harden the build wrapper so a produced hybrid ISO is preserved even if live-build exits nonzero after creating the binary image.
