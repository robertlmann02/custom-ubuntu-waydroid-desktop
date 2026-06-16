# Changelog

## Unreleased

- Update installed desktop defaults to match the latest source-desktop taskbar: bottom Zorin-blue panel, 48px height, flush-left Menu button, and no reserved Show Apps gap.
- Switch the bundled public boot logo artwork to the blue desktop mark used by the ISO branding.
- Add Geary Mail as the default mail handler for `mailto:` links and RFC 822 message files.
- Prepackage Steam and ONLYOFFICE Desktop Editors in the custom desktop build.
- Bake in GNOME theme defaults for bottom panel/start-menu workflow, app indicators, blur, and transparency.
- Add generic boot-logo assets plus Plymouth and GRUB boot-branding setup.
- Harden the build wrapper so a produced hybrid ISO is preserved even if live-build exits nonzero after creating the binary image.
