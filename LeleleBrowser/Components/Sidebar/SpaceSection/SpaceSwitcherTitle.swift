// Licensed under GPL-3.0. See LICENSE.
//
//  SpaceSwitcherTitle.swift
//  LeleleBrowser
//
//  A space's name row between its favorites and its pinned tabs, as in Arc. Clicking it folds the pinned tabs.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SpaceSwitcherTitle: View {
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(\.leleleSettings) private var leleleSettings
    @Environment(\.openSettings) private var openSettings
    @ObservedObject private var dragSession = LeleleBrowserDragSessionManager.shared
    @State private var isHovering = false

    let spaceID: UUID
    let onNewSpace: () -> Void

    private var currentSpace: SpaceRecord? {
        tabs.space(spaceID)
    }

    var body: some View {
        if let space = currentSpace {
            // Also the pin target for a space whose pinned section is empty.
            let pinned = Parent.pinned(spaceID: space.id)
            let isDropTarget = dragSession.isDragging && dragSession.activeZone == .target(pinned)
            LeleleBrowserDropZoneHostView(zoneID: .target(pinned), manager: dragSession, onDrop: { itemID in
                let group = tabs.selectedItems(in: windowState)
                if group.contains(itemID) {
                    tabs.pin(group, to: pinned)
                    windowState.multiSelection.clear()
                } else {
                    tabs.pin(itemID, to: pinned)
                }
            }) {
                HStack(spacing: 0) {
                    // As in Arc: the row folds the pinned section, the ellipsis holds the space menu.
                    Button(action: { toggleCollapsed(space) }) {
                        HStack(spacing: LeleleBrowserDesign.Spacing.md) {
                            leadingIcon(space)
                                .frame(width: LeleleBrowserDesign.Size.favicon)
                            title(space)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if isHovering, windowState.privateTree == nil {
                        Menu {
                            menuContent(current: space)
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: LeleleBrowserDesign.Size.rowGlyph, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: LeleleBrowserDesign.Size.favicon, height: LeleleBrowserDesign.Size.favicon)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .menuIndicator(.hidden)
                        .fixedSize()
                    }
                }
                .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
                // Same box and hover fill as a tab row.
                .frame(height: LeleleBrowserDesign.Tab.height)
                .leleleTabSurface(selected: false, hovered: isHovering || isDropTarget)
                .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Tab.radius))
                .onHoverTracking { isHovering = $0 }
            }
        }
    }

    private func hasPinned(_ space: SpaceRecord) -> Bool {
        !tabs.children(of: .pinned(spaceID: space.id)).isEmpty
    }

    private func toggleCollapsed(_ space: SpaceRecord) {
        guard hasPinned(space) else { return }
        withAnimation(LeleleBrowserDesign.Motion.standard) {
            tabs.setPinnedCollapsed(!tabs.isPinnedCollapsed(space: space.id), space: space.id)
        }
    }

    /// The space icon, a chevron on hover when there are pinned tabs to fold.
    @ViewBuilder
    private func leadingIcon(_ space: SpaceRecord) -> some View {
        if isHovering, hasPinned(space) {
            Image(systemName: tabs.isPinnedCollapsed(space: space.id) ? "chevron.right" : "chevron.down")
                .font(.system(size: LeleleBrowserDesign.Size.rowGlyph, weight: .semibold))
                .foregroundStyle(.secondary)
        } else if space.isAgent {
            Image(systemName: "sparkles").foregroundStyle(LeleleBrowserDesign.Surface.agentGradient)
        } else if SpaceIcon.isDot(space.icon) {
            Circle()
                .fill(space.accentColor)
                .frame(width: LeleleBrowserDesign.Spacing.sm, height: LeleleBrowserDesign.Spacing.sm)
        } else {
            SpaceIcon(space.icon).foregroundStyle(.secondary)
        }
    }

    private func title(_ space: SpaceRecord) -> some View {
        let title = Text(space.name)
            .foregroundStyle(.primary)
            .font(LeleleBrowserDesign.Font.label)
            .lineLimit(1)
            .fixedSize()
        // A name too long for the title row fades out, the way a tab row's title does.
        return ViewThatFits(in: .horizontal) {
            title
            title
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .leleleTrailingFade()
        }
    }

    @ViewBuilder
    private func menuContent(current: SpaceRecord) -> some View {
        ForEach(tabs.orderedSpaces) { space in
            Button {
                tabs.setSpace(space.id, in: windowState)
            } label: {
                if space.id == current.id {
                    Label(space.name, systemImage: "checkmark")
                } else {
                    Text(space.name)
                }
            }
        }
        Divider()
        Button("New Space…", systemImage: "plus", action: onNewSpace)
        Button("Space Settings", systemImage: "gearshape") {
            SettingsNavigation.shared.currentSettingsTab = .spaces
            openSettings()
        }
    }
}
