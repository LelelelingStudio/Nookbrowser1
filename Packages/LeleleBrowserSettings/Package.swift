// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserSettings",
    defaultLocalization: "en",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserSettings", targets: ["LeleleBrowserSettings"]),
    ],
    targets: [
        .target(
            name: "LeleleBrowserSettings",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
