// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarHoverOverlayView.swift
//  LeleleBrowser
//
//  Created by Jonathan Caudill on 2025-09-13.
//

import SwiftUI
import AppKit
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SidebarHoverOverlayView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @EnvironmentObject var hoverManager: HoverSidebarManager
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(CommandPalette.self) private var commandPalette
    @Environment(\.leleleSettings) var leleleSettings

    private let cornerRadius: CGFloat = LeleleBrowserDesign.Radius.lg
    private let horizontalInset: CGFloat = LeleleBrowserDesign.Spacing.md
    private let verticalInset: CGFloat = LeleleBrowserDesign.Spacing.md

    var body: some View {
        // Only render overlay plumbing when the real sidebar is collapsed
        if !windowState.isSidebarVisible {
            ZStack(alignment: leleleSettings.sidebarPosition == .left ? .leading : .trailing) {
                // Edge hover hotspot
                Color.clear
                    .frame(width: hoverManager.triggerWidth)
                    .contentShape(Rectangle())
                    .onHoverTracking { isIn in
                        if isIn && !windowState.isSidebarVisible {
                            withAnimation(LeleleBrowserDesign.Motion.quick) {
                                hoverManager.isOverlayVisible = true
                            }
                        }
                        NSCursor.arrow.set()
                    }

                if hoverManager.isOverlayVisible {
                    SpacesSideBarView()
                        .spaceThemeAppearance(overlayTheme)
                        .frame(width: windowState.sidebarWidth)
                        .environmentObject(browserManager)
                        .environment(windowState)
                        .environment(commandPalette)
                        .environmentObject(browserManager.gradientColorManager)
                        .frame(maxHeight: .infinity)
                        // Clip the floating surface, not descendants: the expanded address
                        // panel is anchored here but deliberately extends over the page.
                        .background {
                            sidebarBackground
                                .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(cornerRadius))
                        }
                        .alwaysArrowCursor()
                        .padding(leleleSettings.sidebarPosition == .left ? .leading : .trailing, horizontalInset)
                        .padding(.vertical, verticalInset)
                        .transition(
                            .move(edge: leleleSettings.sidebarPosition == .left ? .leading : .trailing)
                                .combined(with: .opacity)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: leleleSettings.sidebarPosition == .left ? .topLeading : .topTrailing)
            // Container remains passive; only overlay/hotspot intercept
        }
    }

    private var overlayTheme: SpaceTheme? {
        guard !windowState.isIncognito, let spaceID = windowState.spaceID, spaceID != browserManager.tabs.agentSpaceID else { return nil }
        return browserManager.tabs.space(spaceID)?.theme
    }

    /// The docked sidebar's own background, so the overlay reads as the same sidebar.
    private var sidebarBackground: some View {
        let accent = windowState.isIncognito ? SpaceGradient.incognito.primaryColor : browserManager.gradientColorManager.accentColor
        let isAgent = windowState.spaceID != nil && windowState.spaceID == browserManager.tabs.agentSpaceID
        return SpaceChromeBackground(theme: overlayTheme, accent: accent, isActive: true)
            .spaceThemeAppearance(overlayTheme)
            .overlay(windowState.isIncognito ? LeleleBrowserDesign.Surface.privateTint : Color.clear)
            .overlay(Rectangle().fill(LeleleBrowserDesign.Surface.agentGradient).opacity(isAgent ? LeleleBrowserDesign.Surface.agentChromeOpacity : 0))
    }
}
