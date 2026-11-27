# NOTICE

Lelele Browser is a fork of **Nook** (<https://github.com/nook-browser/Nook>), originally created by Bain Gurley and contributors. The upstream code is licensed under the **GNU General Public License v3.0**. A verbatim copy of that license is in [LICENSE](./LICENSE).

## Modifications in this fork

Changed on 2026-11-26 by Leleleling Studio:

- Renamed the project, targets, packages, Swift symbols, resources and documentation from Nook to Lelele Browser.
- Replaced the application icon and brand assets with Lelele Browser artwork.
- Changed the bundle identifiers to `com.leleleling.browser` (macOS) and `com.leleleling.browser.ios` (iOS).
- Replaced the URL scheme `nook://` with `lelele://`.
- Added a localization layer with automatic system-language detection and English / Simplified Chinese overrides.
- Added memory-saver refinements on top of the upstream tab management modes.
- Replaced update, filter-list and documentation endpoints with Lelele Browser placeholders.

All modifications remain under GPL-3.0. The Nook name, wordmark and icon are not used by this fork.

## Third-party components

This project includes or depends on third-party code under its own licenses. The authoritative license text lives with each component.

| Component | License | Location |
|---|---|---|
| adblock-rust FFI wrapper | MPL-2.0 | `LeleleBrowser/ThirdParty/AdblockRustFFI/` |
| BigUIPaging | MIT | `LeleleBrowser/ThirdParty/BigUIPaging/` |
| uBlock Origin scriptlets | GPL-3.0-or-later | `Packages/LeleleBrowserBlocker/ThirdParty/ubo-scriptlets/` |
| Sparkle | MIT | SwiftPM dependency |
| FaviconFinder | MIT | SwiftPM dependency |
| Garnish and other SwiftPM dependencies | See each package | `LeleleBrowser.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` |

The vendored adblock FFI binary keeps its original C symbol names (`nook_adblock_*`) and module name for ABI compatibility with the committed `.xcframework`. These are internal implementation identifiers, not part of the Lelele Browser user interface.
