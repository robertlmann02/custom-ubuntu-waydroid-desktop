# Wallpaper Release: A Friendly First Linux Desktop

This release is focused on the new custom MI Linux wallpaper experience and a more welcoming first boot for people who are new to Linux.

## Why this release is exciting

- **New-user friendly:** the desktop is designed to feel familiar right away, with a bottom taskbar, a real Menu button, app indicators, and a clean dark look.
- **Custom wallpaper identity:** the ISO ships the custom MI Linux wallpaper collection only, so users see the curated desktop art instead of stock Ubuntu wallpapers.
- **Default wallpaper matches the source desktop:** Linux Vanguard is set as the default wallpaper for both light and dark GNOME background settings.
- **Ready for real daily use:** Chrome, Edge, Geary Mail, Rhythmbox Music, Steam, ONLYOFFICE, Wine, Winetricks, Flatpak support, and Waydroid are included.
- **No Snap clutter:** Snap is pinned out by policy for a cleaner apt-based desktop experience.
- **Safer first steps:** ClamAV/ClamTK plus rootkit scan tooling are included with low-priority automatic timers.

## Wallpaper verification target

The built ISO should contain only the MI Linux wallpaper set under:

```text
/usr/share/backgrounds/mann-linux-wallpapers/
```

The default wallpaper is:

```text
2026-06-21-09-06-36-mi_linux_12_linux_vanguard_1920x1080.jpg
```

Ubuntu/GNOME stock wallpapers are removed from the live image during the chroot hook.
