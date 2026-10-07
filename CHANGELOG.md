# Changelog

All notable changes to AR glTF Material Forge are documented here.

## 1.3.1 — 2026-10-07

### Fixed

- Removed the scroll area from the main panel completely.
- Rebalanced card heights, header spacing, section spacing, and typography so all eight tools remain visible simultaneously inside the fixed-size panel.
- The main panel no longer requires vertical scrolling at any supported UI state.

## 1.3.0 — 2026-10-07

### Added

- Added a dedicated installer/updater window that opens when the MZP is run or dropped into 3ds Max.
- Added automatic installed-version detection.
- Added explicit **Install** and **Update** states.
- Added a persistent `version.txt` marker for future update detection.

### Fixed

- Fixed the persistent toolbar button continuing to call the old in-memory panel after an in-session update.
- Existing toolbar actions are now disconnected from stale callbacks and rebound to the newly reloaded application module.
- Updates now replace the installed payload as a complete unit to prevent stale files from older versions.

## 1.2.0 — 2026-10-07

### Changed

- Increased the fixed panel size for improved readability.
- Increased UI typography, card size, and icon size.
- Added a custom frameless title bar.
- Added a larger modern close button with hover and pressed states.
- Preserved the two-column tool layout.

### Included tools

- Remove V-Ray 2Sided Wrapper
- Remove V-Ray Blend Wrapper
- Keep Base Color Branch Only
- Flatten Base Color to Bitmap
- Clean Orphan Slate Nodes
- Purge Unused Materials
- Disable Extra glTF Extensions
- Show Textures in Viewport

## 1.1.0 — 2026-10-07

- Reworked the panel into a larger fixed-size two-column layout.
- Improved typography and icon readability.
- Changed the panel from the smaller initial layout to a dedicated floating tool window.

## 1.0.0 — 2026-10-07

- Initial packaged MZP installer.
- Added persistent toolbar integration.
- Added startup loader.
- Added the initial material-preparation tool set.
