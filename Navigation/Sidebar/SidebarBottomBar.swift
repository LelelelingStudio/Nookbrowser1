// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarBottomBar.swift
//  LeleleBrowser
//
//  Created by Aether on 15/11/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

/// Bottom bar of the sidebar containing menu button, spaces list, and new space button
struct SidebarBottomBar: View {
    @Environment(\.leleleSettings) private var leleleSettings
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(CommandPalette.self) private var commandPalette
    @Binding var isMenuButtonHovered: Bool
    let onMenuTap: () -> Void
    let onNewSpaceTap: () -> Void
    let onMenuHover: (Bool) -> Void
    
    var body: some View {
        GeometryReader { geo in
            let reserve = sideReserve
            ZStack {
                // The space dots sit on the bar's center line whatever the side clusters hold.
                if !windowState.isIncognito {
                    SpacesList()
                        .frame(width: max(geo.size.width - 2 * reserve, 0))
                        .environmentObject(browserManager)
                        .environment(windowState)
                }

                HStack(alignment: .center, spacing: LeleleBrowserDesign.SidebarChrome.gap) {
                    // Above the space dots, so its hint draws over them.
                    menuButton
                        .zIndex(1)

                    if leleleSettings.showAIAssistant {
                        Button("Toggle AI Assistant", systemImage: "sparkle") {
                            browserManager.toggleAISidebar(for: windowState)
                        }
                        .leleleSidebarIconButtons()
                        .help("Toggle AI Assistant")
                    }

                    Spacer(minLength: 0)

                    // Hide new space button in incognito windows
                    if !windowState.isIncognito {
                        newSpaceButton
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: LeleleBrowserDesign.Size.bottomBar)
        .padding(.horizontal, LeleleBrowserDesign.Spacing.sidebarInset)
    }

    /// Room kept clear on each side of the dots: the wider cluster plus a gap.
    private var sideReserve: CGFloat {
        let button = LeleleBrowserDesign.SidebarChrome.button, gap = LeleleBrowserDesign.SidebarChrome.gap
        let left = leleleSettings.showAIAssistant ? 2 * button + gap : button
        return left + gap
    }

    private var menuButton: some View {
        ZStack {
            Button("Menu", systemImage: "archivebox") {
                onMenuTap()
            }
            // A finished download bounces the button its icon flew into.
            .symbolEffect(.bounce, value: browserManager.downloadManager.completedCount)
            .leleleSidebarIconButtons()
            .anchorPreference(key: DownloadsButtonAnchorKey.self, value: .bounds) { $0 }
            .onHoverTracking { isHovered in
                isMenuButtonHovered = isHovered
                onMenuHover(isHovered)
            }
            // Arc's hint beside the button: where it leads.
            .overlay(alignment: .leading) {
                if isMenuButtonHovered {
                    Text("View Library")
                        .font(LeleleBrowserDesign.Font.label)
                        .foregroundStyle(.white)
                        .padding(.horizontal, LeleleBrowserDesign.Spacing.md)
                        .frame(height: LeleleBrowserDesign.Size.iconButton)
                        .background(Color.black.opacity(0.85), in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
                        .fixedSize()
                        .offset(x: LeleleBrowserDesign.SidebarChrome.button + LeleleBrowserDesign.Spacing.xs)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .offset(x: -4)))
                }
            }
            .animation(LeleleBrowserDesign.Motion.quick, value: isMenuButtonHovered)
            .zIndex(1)

            DownloadIndicator()
                .offset(x: LeleleBrowserDesign.Spacing.lg, y: -LeleleBrowserDesign.Spacing.lg)
        }
    }
    
    /// Arc's create menu: space and folder, then page tools, then panes and tabs.
    private var newSpaceButton: some View {
        Menu {
            Button("New Space", systemImage: "plus.square.on.square") {
                onNewSpaceTap()
            }

            Button("New Folder", systemImage: "folder.badge.plus") {
                if let spaceID = windowState.spaceID {
                    tabs.createFolderForRename(in: .tabs(spaceID: spaceID), after: nil)
                }
            }

            Menu {
                ForEach(LiveFolderMenuItem.all, id: \.title) { entry in
                    Button(entry.title, systemImage: entry.symbol) {
                        if let spaceID = windowState.spaceID {
                            tabs.createLiveFolder(entry.source, in: spaceID)
                        }
                    }
                }
                Button("New Feed Folder…", systemImage: "dot.radiowaves.up.forward") {
                    if let spaceID = windowState.spaceID {
                        browserManager.presentFeedFolderPrompt(in: spaceID)
                    }
                }
            } label: {
                Label("New Live Folder", systemImage: "folder.badge.gearshape")
            }

            Divider()

            Button("New Boost", systemImage: "wand.and.stars") {
                browserManager.openBoostPanel(in: windowState)
            }
            .disabled(!selectedPageIsWeb)

            Divider()

            Button("New Split", systemImage: "rectangle.split.2x1") {
                if let itemID = tabs.open(url: TabsController.homeURL, in: windowState, placement: .background) {
                    browserManager.splitManager.enterSplit(with: itemID, in: windowState)
                }
            }
            .disabled(windowState.selectedItemID == nil || windowState.split != nil)

            Button("New Tab", systemImage: "plus.square") {
                commandPalette.open()
            }
        } label: {
            Label("Actions", systemImage: "plus")
        }
        .menuStyle(.button)
        .leleleSidebarIconButtons()
    }

    private var selectedPageIsWeb: Bool {
        guard let url = tabs.selectedSession(in: windowState)?.url else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

/// The live folder sources the sidebar's create menus offer, besides feeds.
struct LiveFolderMenuItem {
    let title: String
    let symbol: String
    let source: LiveSource

    static let all = [
        LiveFolderMenuItem(title: "New Pull Requests Folder", symbol: "arrow.triangle.pull", source: .githubPulls),
        LiveFolderMenuItem(title: "New Issues Folder", symbol: "smallcircle.filled.circle", source: .githubIssues),
        LiveFolderMenuItem(title: "New Notifications Folder", symbol: "bell", source: .githubNotifications),
        LiveFolderMenuItem(title: "New Asana Tasks Folder", symbol: "checkmark.circle", source: .asanaTasks),
    ]
}
