# Changelog

## Unreleased

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
