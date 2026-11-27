// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarWhatsNewCard.swift
//  LeleleBrowser
//
//  Created by Bain Gurley on 22/09/2026.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserUI
import LeleleBrowserWeb

/// Shown once after an update, in the update notification's slot. The whole card opens the
/// release notes; the corner button dismisses it. Either way it is gone until the next version.
struct SidebarWhatsNewCard: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState
    @State private var isHovering = false

    // One place to point at a designed page later.
    private static let notesBase = "https://github.com/lelele-browser/LeleleBrowser/releases/tag/v"

    var body: some View {
        // The update card owns this slot while an update is pending.
        if let version = browserManager.whatsNewVersion, browserManager.updateAvailability == nil {
            Button {
                if let url = URL(string: Self.notesBase + version) {
                    browserManager.tabs.open(url: url, in: windowState, placement: .newTab)
                }
                browserManager.whatsNewVersion = nil
            } label: {
                VStack(spacing: LeleleBrowserDesign.Spacing.xxs) {
                    Text("What's new in Lelele Browser \(version)")
                        .font(LeleleBrowserDesign.Font.secondary)
                        .foregroundStyle(.primary)
                    Text("See what changed")
                        .font(LeleleBrowserDesign.Font.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LeleleBrowserDesign.Spacing.lg)
                .padding(.vertical, LeleleBrowserDesign.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                if isHovering {
                    Button {
                        browserManager.whatsNewVersion = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(LeleleBrowserDesign.Font.micro)
                            .foregroundStyle(.secondary)
                            .frame(width: LeleleBrowserDesign.Size.cornerButton, height: LeleleBrowserDesign.Size.cornerButton)
                    }
                    .buttonStyle(.plain)
                    .padding(LeleleBrowserDesign.Spacing.xs)
                }
            }
            .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
            .onHoverTracking { isHovering = $0 }
            .animation(LeleleBrowserDesign.Motion.quick, value: isHovering)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}
