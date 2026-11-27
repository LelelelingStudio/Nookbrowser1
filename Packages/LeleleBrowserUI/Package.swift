// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserUI",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserUI", targets: ["LeleleBrowserUI"]),
    ],
    dependencies: [
        .package(path: "../LeleleBrowserBlocker"),
        .package(path: "../LeleleBrowserDesign"),
        .package(path: "../LeleleBrowserSettings"),
        .package(path: "../LeleleBrowserTabsCore"),
        .package(path: "../LeleleBrowserTweaks"),
        .package(path: "../LeleleBrowserWeb"),
    ],
    targets: [
        .target(
            name: "LeleleBrowserUI",
            dependencies: [
                .product(name: "LeleleBrowserBlocker", package: "LeleleBrowserBlocker"),
                .product(name: "LeleleBrowserDesign", package: "LeleleBrowserDesign"),
                .product(name: "LeleleBrowserSettings", package: "LeleleBrowserSettings"),
                .product(name: "LeleleBrowserTabsCore", package: "LeleleBrowserTabsCore"),
                .product(name: "LeleleBrowserTweaks", package: "LeleleBrowserTweaks"),
                .product(name: "LeleleBrowserWeb", package: "LeleleBrowserWeb"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
