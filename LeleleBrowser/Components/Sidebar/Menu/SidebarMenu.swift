// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarMenu.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 23/09/2025.
//

import AppKit
import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SidebarMenu: View {
    @Environment(BrowserWindowState.self) private var windowState
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(\.leleleSettings) var leleleSettings

    private let tabColumnWidth: CGFloat = 110

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if leleleSettings.sidebarPosition == .left{
                tabs
            }
            VStack {
                switch windowState.sidebarMenuSelectedTab {
                case .history:
                    SidebarMenuHistoryTab()
                case .downloads:
                    SidebarMenuDownloadsTab()
                case .spaces:
                    SidebarMenuSpacesTab(onOpenSpace: openSpace, onNewSpace: newSpace)
                case .archive:
                    SidebarMenuArchiveTab(onRestore: close)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if leleleSettings.sidebarPosition == .right{
                tabs
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
    }

    private func close() {
        LibraryMotion.close(windowState)
    }

    private func openSpace(_ id: UUID) {
        close()
        withAnimation(LeleleBrowserDesign.Motion.standard) {
            browserManager.tabs.setSpace(id, in: windowState)
        }
    }

    private func newSpace() {
        close()
        withAnimation(LeleleBrowserDesign.Motion.standard) {
            windowState.spaceDraftTheme = .randomPreset()
        }
    }

    var tabs: some View{
        VStack {

            Spacer()
            VStack(spacing: LeleleBrowserDesign.Spacing.xxl) {
                SidebarMenuTab(
                    image: "clock",
                    activeImage: "clock.fill",
                    title: "History",
                    isActive: windowState.sidebarMenuSelectedTab == .history,
                    action: {
                        windowState.sidebarMenuSelectedTab = .history
                    }
                )
                if !windowState.isIncognito {
                SidebarMenuTab(
                    image: "archivebox",
                    activeImage: "archivebox.fill",
                    title: "Archive",
                    isActive: windowState.sidebarMenuSelectedTab == .archive,
                    action: {
                        windowState.sidebarMenuSelectedTab = .archive
                    }
                )
                }
                SidebarMenuTab(
                    image: "square.on.square",
                    activeImage: "square.fill.on.square.fill",
                    title: "Spaces",
                    isActive: windowState.sidebarMenuSelectedTab == .spaces,
                    action: {
                        windowState.sidebarMenuSelectedTab = .spaces
                    }
                )
                SidebarMenuTab(
                    image: "arrow.down.circle",
                    activeImage: "arrow.down.circle.fill",
                    title: "Downloads",
                    isActive: windowState.sidebarMenuSelectedTab == .downloads,
                    action: {
                        windowState.sidebarMenuSelectedTab = .downloads
                    }
                )
            }
            
            Spacer()
            HStack {
                Button("Back", systemImage: "arrow.backward", action: close)
                .leleleIconButtons()
                Spacer()
            }
            .padding(.leading, LeleleBrowserDesign.Spacing.md)
            .padding(.bottom, LeleleBrowserDesign.Spacing.md)
        }
        .padding(LeleleBrowserDesign.Spacing.md)
        .frame(width: tabColumnWidth)
        .frame(maxHeight: .infinity)
        .background(LeleleBrowserDesign.Surface.fill)
    }
}
