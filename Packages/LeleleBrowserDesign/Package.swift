// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserDesign",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserDesign", targets: ["LeleleBrowserDesign"]),
    ],
    targets: [
        .target(name: "LeleleBrowserDesign", swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
