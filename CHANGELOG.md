# Changelog

## Unreleased

- Downgrade/pin the ISO kernel recipe to Ubuntu generic `7.0.0-27-generic` because Waydroid cannot use the newer mainline `7.1.1-070101-generic` kernel without Android binder support.
- Add a persistent Waydroid binder setup service that loads `binder_linux`, mounts binderfs, and creates the `/dev/anbox-*` device links Waydroid expects.
- Keep optional local Secure Boot signing support only for future custom/mainline kernel builds; the default Waydroid-compatible Ubuntu generic kernel path no longer requires the MOK workaround.
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
