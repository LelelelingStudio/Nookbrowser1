// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserTabsCore",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserTabsCore", targets: ["LeleleBrowserTabsCore"]),
    ],
    targets: [
        .target(name: "LeleleBrowserTabsCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "LeleleBrowserTabsCoreTests", dependencies: ["LeleleBrowserTabsCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
