// Licensed under GPL-3.0. See LICENSE.
//
//  SpaceView.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 04/08/2025.
//
//  A space's sidebar outline: pinned section rows, the separator and new-tab button, then
//  tabs section rows. Rows come flattened from `TabsController.rows(space:)`; each section is
//  one drop zone whose rows all share `Tab.stride` height (including vertical card insets), which the
//  drop position math in `LeleleBrowserDragSessionManager` relies on.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SpaceView: View {
    let spaceID: UUID
    let isActive: Bool
    @Binding var isSidebarHovered: Bool

    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(CommandPalette.self) private var commandPalette
    @Environment(TabOrganizerManager.self) private var tabOrganizerManager
    @Environment(\.leleleSettings) private var leleleSettings
    @ObservedObject private var dragSession = LeleleBrowserDragSessionManager.shared
    @State private var isNewTabHovering = false
    @State private var isUserScrolling = false
    @State private var showsScrollIndicator = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(spaceID: UUID, isActive: Bool, isSidebarHovered: Binding<Bool>) {
        self.spaceID = spaceID
        self.isActive = isActive
        self._isSidebarHovered = isSidebarHovered
    }

    private var tabs: TabsController { browserManager.tabs }

    private var outerWidth: CGFloat {
        let visibleWidth = windowState.sidebarWidth
        if visibleWidth > 0 {
            return visibleWidth
        }
        return max(browserManager.getSavedSidebarWidth(for: windowState), 0)
    }

    private var innerWidth: CGFloat {
        max(outerWidth - LeleleBrowserDesign.Spacing.sidebarInset * 2, 0)
    }

    var body: some View {
        let rows = tabs.rows(space: spaceID)
        // A folded pinned section still shows its selected tab, as Arc does.
        let selected = windowState.spaceID == spaceID ? windowState.selectedItemID : nil
        let pinned = rows.filter {
            $0.section == .pinned && (!tabs.isPinnedCollapsed(space: spaceID) || $0.id == selected)
        }
        let regular = rows.filter { $0.section == .tabs }
        let split = splitPair(in: rows)

        ScrollView(.vertical) {
            VStack(spacing: LeleleBrowserDesign.Spacing.sectionGap) {
                // An empty pinned section shows a drop slot only while a drag is on.
                if !pinned.isEmpty {
                    sectionList(.pinned(spaceID: spaceID), rows: pinned, split: split, showsTail: false)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }

                VStack(spacing: LeleleBrowserDesign.Spacing.sectionGap) {
                    separatorAndNewTab(regular: regular)
                    sectionList(.tabs(spaceID: spaceID), rows: regular, split: split, showsTail: true)
                }
            }
            .animation(reduceMotion || dragSession.isDragging ? nil : LeleleBrowserDesign.Motion.tabClose, value: pinned.isEmpty)
            .frame(minWidth: 0, maxWidth: innerWidth, alignment: .leading)
            // Inset the rows, not the scroll viewport: the indicator belongs at the sidebar edge.
            .padding(.horizontal, LeleleBrowserDesign.Spacing.sidebarInset)
        }
        .contentMargins(.trailing, 0, for: .scrollIndicators)
        .scrollIndicators(showsScrollIndicator && !windowState.isSidebarResizeHovered ? .visible : .hidden)
        .onScrollPhaseChange { _, phase in
            // Tracking alone (a finger resting on the pad) is not scrolling.
            isUserScrolling = phase == .interacting || phase == .decelerating
            if isUserScrolling { showsScrollIndicator = true }
        }
        .task(id: isUserScrolling) {
            guard !isUserScrolling else { return }
            do {
                try await Task.sleep(for: .milliseconds(650))
                showsScrollIndicator = false
            } catch {
                // A new scroll cancels the pending hide.
            }
        }
        .onDisappear {
            isUserScrolling = false
            showsScrollIndicator = false
        }
        .contentShape(Rectangle())
        .frame(minWidth: 0, maxWidth: outerWidth, alignment: .leading)
    }

    // MARK: - Sections

    private func sectionList(_ section: Parent, rows allRows: [Row], split: SplitPair?, showsTail: Bool) -> some View {
        // The pair is one row at its anchor; the other half's own row is hidden.
        let rows = split.map { split in allRows.filter { !split.contains($0.id) || $0.id == split.anchorID } } ?? allRows
        let zone = DropZoneID.section(section)
        let position = dragSession.dropPosition?.zone == zone ? dragSession.dropPosition : nil
        let isSource = dragSession.isDragging && dragSession.sourceZone == zone
        let isDestination = position != nil || (isSource && dragSession.dropPosition == nil && dragSession.activeZone == zone)
        let boundary = position.map { $0.index + ($0.placement == .after ? 1 : 0) }
        let preview = TabReorderPreview(
            rows: rows, draggedID: dragSession.draggedItem?.tabId ?? spaceID,
            destinationBoundary: boundary, sourceInThisSection: isSource,
            isDestination: isDestination, isIntoFolder: position?.placement == .into
        )
        return LeleleBrowserDropZoneHostView(
            zoneID: zone,
            layout: .rows(rows),
            manager: dragSession,
            onDrop: { itemID, position in
                let group = tabs.selectedItems(in: windowState)
                let land = { tabs.drop(itemID, at: position, section: section, rows: rows) }
                if group.contains(itemID) {
                    tabs.dropGroup(group, dragged: itemID, drop: land)
                    windowState.multiSelection.clear()
                } else {
                    land()
                }
            }
        ) {
            VStack(spacing: 0) {
                let content = Group {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        rowView(row, zone: zone, split: split, isDropTarget: position == DropPosition(zone: zone, index: index, placement: .into))
                            .padding(.leading, CGFloat(row.depth) * LeleleBrowserDesign.Spacing.folderIndent)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity
                            ))
                            // Zen keeps a dimmed source in place while its floating card
                            // follows the pointer freely; only the insertion marker moves.
                            .opacity(preview.containsDraggedRow(id: row.id) ? (dragSession.isFinishingDrag ? 0 : 0.3) : 1)
                            // Only release makes the neighboring rows move aside, in sync
                            // with the native floating card's 100ms landing animation.
                            .offset(y: dragSession.isFinishingDrag ? CGFloat(preview.rowOffset(for: row.id)) * LeleleBrowserDesign.Tab.stride : 0)
                            .animation(reduceMotion ? nil : LeleleBrowserDesign.Motion.tabReorder, value: dragSession.isFinishingDrag)
                    }
                }
                if dragSession.isDragging {
                    VStack(spacing: 0) { content }
                } else {
                    LazyVStack(spacing: 0) { content }
                        // Keep row identities stable so remaining tabs slide into the gap.
                        // Apply the same layout animation to temporary and pinned rows.
                        .animation(reduceMotion ? nil : LeleleBrowserDesign.Motion.tabClose, value: rows.map(\.id))
                }
                if dragSession.isFinishingDrag, !isSource, isDestination, preview.gapIndex != nil, !rows.isEmpty {
                    Color.clear.frame(height: LeleleBrowserDesign.Tab.stride)
                }

                if allRows.isEmpty, !showsTail {
                    emptySectionSlot(isActive: dragSession.activeZone == zone)
                }

                if showsTail {
                    Color.clear
                        .contentShape(Rectangle())
                        .conditionalWindowDrag()
                        .frame(minHeight: LeleleBrowserDesign.Size.dropTail, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 0, maxWidth: innerWidth, alignment: .leading)
            .overlay(alignment: .topLeading) {
                if !dragSession.isFinishingDrag, let gap = boundary, preview.gapIndex != nil {
                    dropLine
                        .padding(.leading, dropLineIndent)
                        .offset(y: CGFloat(gap) * LeleleBrowserDesign.Tab.stride)
                        .animation(reduceMotion ? nil : LeleleBrowserDesign.Motion.tabReorder, value: gap)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            // Rows have their own menus; this one covers the gaps and the tail of the section.
            .contextMenu {
                Button {
                    tabs.createFolderForRename(in: section, after: tabs.children(of: section).last?.id)
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
        }
    }

    private func emptySectionSlot(isActive: Bool) -> some View {
        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md)
            .strokeBorder(style: StrokeStyle(lineWidth: LeleleBrowserDesign.Size.hairlineWidth, dash: [LeleleBrowserDesign.Spacing.sm, LeleleBrowserDesign.Spacing.xs]))
            .foregroundStyle(isActive ? LeleleBrowserDesign.Surface.dropBorderActive : LeleleBrowserDesign.Surface.dropBorderIdle)
            .background(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md).fill(isActive ? LeleleBrowserDesign.Surface.fillPressed : Color.clear))
            .frame(height: LeleleBrowserDesign.Tab.height)
            .padding(.vertical, LeleleBrowserDesign.Tab.verticalInset)
            .animation(LeleleBrowserDesign.Motion.quick, value: isActive)
    }

    /// Leading inset of a drop line. The overlay spans the row including its depth padding.
    private var dropLineIndent: CGFloat {
        CGFloat(dragSession.dropDepth) * LeleleBrowserDesign.Spacing.folderIndent
    }

    private var dropLine: some View {
        HStack(spacing: 0) {
            Circle()
                .strokeBorder(Color.primary.opacity(0.7), lineWidth: LeleleBrowserDesign.Tab.dropIndicatorHeight)
                .frame(width: LeleleBrowserDesign.Tab.dropIndicatorDot, height: LeleleBrowserDesign.Tab.dropIndicatorDot)
            Capsule()
                .fill(Color.primary.opacity(0.7))
                .frame(height: LeleleBrowserDesign.Tab.dropIndicatorHeight)
        }
        .frame(height: LeleleBrowserDesign.Tab.dropIndicatorDot)
        .offset(y: -LeleleBrowserDesign.Tab.dropIndicatorDot / 2)
    }

    @ViewBuilder
    private func rowView(_ row: Row, zone: DropZoneID, split: SplitPair?, isDropTarget: Bool) -> some View {
        if let split, row.id == split.anchorID {
            SplitTabRow(left: split.left, right: split.right, zoneID: zone)
        } else {
            let session = tabs.session(for: row.item.id)
            let group = windowState.multiSelection.contains(row.id) ? tabs.selectedItems(in: windowState) : []
            LeleleBrowserDragSourceView(
                item: LeleleBrowserDragItem(tabId: row.item.id, title: tabs.title(for: row.item), urlString: tabs.currentURL(for: row.item)?.absoluteString ?? "",
                                    count: group.contains(row.id) ? group.count : nil),
                icon: row.item.isFolder ? Image(systemName: "folder.fill") : session?.favicon,
                zoneID: zone,
                manager: dragSession
            ) {
                if row.item.isFolder {
                    TabFolderView(item: row.item, spaceID: spaceID, isDropTarget: isDropTarget)
                } else {
                    SpaceTab(item: row.item, hasChildren: row.hasChildren)
                }
            }
            .id(row.item.id)
        }
    }

    // MARK: - Split

    private struct SplitPair {
        let left: Item
        let right: Item
        /// The row the pair is drawn at.
        let anchorID: UUID

        func contains(_ id: UUID) -> Bool { id == left.id || id == right.id }
    }

    /// The window's split pair, anchored at the left tab's row, or the right tab's when the left
    /// has no visible row (a favorite, or inside a closed folder).
    private func splitPair(in rows: [Row]) -> SplitPair? {
        guard let split = windowState.split,
              let left = tabs.item(split.leftItemID), let right = tabs.item(split.rightItemID),
              let anchor = [left.id, right.id].first(where: { id in rows.contains { $0.id == id } })
        else { return nil }
        return SplitPair(left: left, right: right, anchorID: anchor)
    }

    // MARK: - Separator and New Tab

    private func separatorAndNewTab(regular: [Row]) -> some View {
        let looseTabs = regular.filter { $0.depth == 0 && !$0.item.isFolder }.map(\.item.id)
        let kept = [windowState.selectedItemID, windowState.split?.leftItemID, windowState.split?.rightItemID].compactMap { $0 }
        let clearable = tabs.tabsToClear(in: spaceID, keeping: kept)
        return VStack(spacing: LeleleBrowserDesign.Spacing.xs) {
            SpaceSeparator(
                isHovering: $isSidebarHovered,
                // Clear keeps the window's current tabs; a tab goes with its whole trail.
                onClear: { clearable.forEach(tabs.remove) },
                onOrganize: leleleSettings.tabOrganizerEnabled && tabOrganizerManager.isAvailable ? {
                    Task {
                        await tabOrganizerManager.organizeTabs(in: spaceID, using: tabs)
                    }
                } : nil,
                isOrganizing: tabOrganizerManager.isOrganizing,
                tabCount: looseTabs.count,
                clearCount: clearable.count
            )
            .padding(.horizontal, LeleleBrowserDesign.Spacing.md)

            if tabs.rows(space: spaceID).allSatisfy({ $0.section != .pinned }), dragSession.isDragging {
                // Reuse the New Tab slot, so revealing an empty pin target cannot push the
                // whole list down beneath the pointer at the start of a drag.
                sectionList(.pinned(spaceID: spaceID), rows: [], split: nil, showsTail: false)
            } else {
                newTabButton
            }
        }
    }

    private var newTabButton: some View {
        Button {
            commandPalette.open()
        } label: {
            HStack(spacing: LeleleBrowserDesign.Spacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: LeleleBrowserDesign.Size.favicon, weight: .medium))
                Text("New Tab")
                    .font(LeleleBrowserDesign.Tab.font)
                Spacer(minLength: 0)
                if isNewTabHovering {
                    Text("⌘T")
                        .font(LeleleBrowserDesign.Font.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(isNewTabHovering ? .secondary : .tertiary)
            .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
            .frame(height: LeleleBrowserDesign.Tab.height)
            .frame(maxWidth: .infinity)
            .background(isNewTabHovering ? LeleleBrowserDesign.Surface.fill : Color.clear)
            .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
            .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
            .padding(.vertical, LeleleBrowserDesign.Tab.verticalInset)
        }
        .buttonStyle(LeleleBrowserTabButtonStyle())
        .onHoverTracking { hovering in
            withAnimation(LeleleBrowserDesign.Motion.hover(hovering)) { isNewTabHovering = hovering }
        }
    }
}
