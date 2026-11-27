<div align="center">
  <img width="230" height="230" src="/assets/lelele-browser-1024.png" alt="Lelele Browser Logo">
  <h1><b>Lelele Browser</b></h1>
  <p>A fast, minimal, sidebar-first browser for macOS.<br>快速、简洁、侧边栏优先的 macOS 浏览器。</p>
</div>

<p align="center">
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-15.5+-blue" alt="macOS 15.5+"></a>
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-5-orange" alt="Swift"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-green" alt="GPL-3.0"></a>
  <a href="https://leleleling.site"><img src="https://img.shields.io/badge/site-leleleling.site-blue" alt="leleleling.site"></a>
</p>

> **Status:** Lelele Browser is a personal fork based on Nook 1.7.0. Branding, bundle IDs, URL scheme, resources and documentation have been replaced. Releases will be published at `leleleling.site` once signing and update infrastructure are ready.

## Features

- **Sidebar-first navigation** — vertical tabs, spaces, pinned tabs and archives.
- **Localization** — follows the system language, with manual **Follow System / English / 简体中文** override in Settings.
- **Memory Saver** — aggressively unloads inactive tabs, with a one-click **Unload All Inactive Tabs** action and memory-pressure handling.
- **Built-in content blocking** — filter lists, cosmetic rules, site tweaks and SponsorBlock.
- **Extensions, downloads, history and command palette** — a complete daily-driver browser core.
- **Launcher support** — drive the browser with `lelele://` links.
- **WebKit-based** — uses the system `WKWebView`, not a bundled Chromium engine.

## Language / 语言

Lelele Browser uses English as the source language. Interface text resolves in this order:

1. The language chosen in **Settings → Language**.
2. The system preferred language when set to **Follow System**.
3. English fallback for any untranslated string.

Currently translated: English and Simplified Chinese. Adding a language means adding an `.lproj` folder to `Packages/LeleleBrowserSettings/Sources/LeleleBrowserSettings/Resources/` and wrapping user-facing strings with `L("...")`.

## Launchers

Raycast, Alfred and scripts can use `lelele://` links. Enable **Allow lelele:// links** in Settings → Links first.

- Open a page: `open "lelele://open?url=https://example.com&space=Work&reuse=1"`
- Search: `open "lelele://search?q=swift%20concurrency&space=Work"`
- Switch space: `open "lelele://space?name=Work"`

Spaces match by exact name (case-insensitive) or UUID. Only `http` and `https` pages open.

## Build from source

### Prerequisites

- macOS 15.6 or later, Apple Silicon
- Xcode 26 or later with the Metal Toolchain component
- A personal Development Team for local signing
- On-device AI features require macOS 26 with Apple Intelligence

```bash
git clone https://github.com/LelelelingStudio/LeleleBrowser.git
cd LeleleBrowser
xcodebuild -downloadComponent MetalToolchain
open LeleleBrowser.xcodeproj
```

Set your Development Team under **Signing & Capabilities**, then press `Cmd + R`.

To build without a signing team:

```bash
xcodebuild -scheme LeleleBrowser -configuration Debug -arch arm64 \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Project structure

```
App/                     macOS entry point, window, menus, delegate
LeleleBrowser/           macOS managers, components, resources, entitlements
Packages/
  LeleleBrowserTabsCore  Tab tree, spaces, on-disk store
  LeleleBrowserSettings  Settings service, language selection, localization resources
  LeleleBrowserDesign    Design tokens
  LeleleBrowserBlocker   Content blocker and FFI wrapper
  LeleleBrowserTweaks    Site tweaks, SponsorBlock, routing
  LeleleBrowserWeb       Tabs, page sessions, history, search, WebKit seams
  LeleleBrowserUI        Shared SwiftUI views and settings tabs
LeleleBrowseriOS/        iOS target, not released yet
Navigation/              Sidebar structure
Onboarding/              First-run flow
CommandPalette/          Command palette
UI/                      Shared controls
scripts/                 Filter list, scriptlet and check tooling
```

The app uses a manager-based architecture. `BrowserManager` is the central coordinator while the `Packages/` modules hold platform-independent model and view code.

## License

Lelele Browser is free software under [GPL-3.0](./LICENSE), inherited from its upstream. You may use, modify and distribute it, including commercially, provided you comply with the GPL when you convey copies.

See [NOTICE.md](./NOTICE.md) for upstream attribution and third-party license details. See [TRADEMARK.md](./TRADEMARK.md) for the separate trademark policy; the Lelele Browser name and icon are not covered by the code license.
