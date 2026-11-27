// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserBlocker",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserBlocker", targets: ["LeleleBrowserBlocker"]),
    ],
    dependencies: [
        .package(path: "../LeleleBrowserSettings"),
    ],
    targets: [
        .binaryTarget(
            name: "NookAdblockFFI",
            path: "../../LeleleBrowser/ThirdParty/AdblockRustFFI/NookAdblock.xcframework"
        ),
        .target(
            name: "LeleleBrowserBlocker",
            dependencies: [
                "NookAdblockFFI",
                .product(name: "LeleleBrowserSettings", package: "LeleleBrowserSettings"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
