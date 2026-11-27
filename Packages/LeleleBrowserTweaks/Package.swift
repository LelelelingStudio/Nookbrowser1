// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserTweaks",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserTweaks", targets: ["LeleleBrowserTweaks"]),
    ],
    dependencies: [
        .package(path: "../LeleleBrowserSettings"),
        .package(path: "../LeleleBrowserBlocker"),
    ],
    targets: [
        .target(
            name: "LeleleBrowserTweaks",
            dependencies: [
                .product(name: "LeleleBrowserSettings", package: "LeleleBrowserSettings"),
                .product(name: "LeleleBrowserBlocker", package: "LeleleBrowserBlocker"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
