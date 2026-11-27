// Licensed under GPL-3.0. See LICENSE.
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeleleBrowserWeb",
    platforms: [.macOS("15.5"), .iOS("26.0")],
    products: [
        .library(name: "LeleleBrowserWeb", targets: ["LeleleBrowserWeb"]),
    ],
    dependencies: [
        .package(path: "../LeleleBrowserTabsCore"),
        .package(path: "../LeleleBrowserSettings"),
        .package(path: "../LeleleBrowserBlocker"),
        .package(path: "../LeleleBrowserTweaks"),
        .package(url: "https://github.com/will-lumley/FaviconFinder.git", from: "5.1.5"),
    ],
    targets: [
        .target(name: "MuteableWKWebView", path: "Sources/MuteableWKWebView", publicHeadersPath: "include"),
        .target(
            name: "LeleleBrowserWeb",
            dependencies: [
                // Page muting reaches a private WebKit call through NSTask and nm; macOS only.
                .target(name: "MuteableWKWebView", condition: .when(platforms: [.macOS])),
                .product(name: "LeleleBrowserTabsCore", package: "LeleleBrowserTabsCore"),
                .product(name: "LeleleBrowserSettings", package: "LeleleBrowserSettings"),
                .product(name: "LeleleBrowserBlocker", package: "LeleleBrowserBlocker"),
                .product(name: "LeleleBrowserTweaks", package: "LeleleBrowserTweaks"),
                .product(name: "FaviconFinder", package: "FaviconFinder"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
