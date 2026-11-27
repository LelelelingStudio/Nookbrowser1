// Licensed under GPL-3.0. See LICENSE.
//
//  EmptyWebsiteView.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 28/07/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserWeb

public struct EmptyWebsiteView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(WindowRegistry.self) var windowRegistry
    @Environment(TabsController.self) private var tabs
    @Environment(\.tabActions) private var actions

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Match the container background so this reads as chrome, not webview content.
                let accent = windowState.isIncognito ? LeleleBrowserDesign.Surface.incognitoAccent : (actions?.accentColor ?? .accentColor)
                let isActive = windowRegistry.activeWindowId == windowState.id

                let theme = windowState.isIncognito ? nil : windowState.spaceDraftTheme ?? windowState.spaceID.flatMap { tabs.space($0)?.theme }
                SpaceChromeBackground(theme: theme, accent: accent, isActive: isActive)
                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
                    .leleleElevation(.raised)
                    .animation(LeleleBrowserDesign.Motion.standard, value: isActive)

                VStack(spacing: 16) {
                    Image(systemName: "moon.stars")
                        .font(LeleleBrowserDesign.Font.display)
                        .blendMode(.overlay)

                    Text("Ah, peace.")
                        .font(LeleleBrowserDesign.Font.title)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
