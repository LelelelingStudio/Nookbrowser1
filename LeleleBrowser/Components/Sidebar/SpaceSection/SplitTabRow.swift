// Licensed under GPL-3.0. See LICENSE.
import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserUI
import LeleleBrowserWeb

/// The window's split pair shown as one sidebar row (from `BrowserWindowState.split`).
/// The halves' visuals are `SplitHalfLabel` in LeleleBrowserUI; this file is the drag source around them.
struct SplitTabRow: View {
    let left: Item
    let right: Item
    /// The drop zone the halves drag from.
    let zoneID: DropZoneID

    @Environment(BrowserWindowState.self) private var windowState
    @State private var isHovering = false

    /// The whole row is the selection while the window shows the pair.
    private var isActive: Bool {
        windowState.selectedItemID == left.id || windowState.selectedItemID == right.id
    }

    var body: some View {
        HStack(spacing: 0) {
            SplitHalfTab(item: left, zoneID: zoneID)
            Rectangle()
                .fill(LeleleBrowserDesign.Surface.hairline)
                .frame(width: LeleleBrowserDesign.Size.hairlineWidth)
                .padding(.vertical, LeleleBrowserDesign.Spacing.sm)
            SplitHalfTab(item: right, zoneID: zoneID)
        }
        .frame(height: LeleleBrowserDesign.Tab.height)
        .leleleTabSurface(selected: isActive, hovered: isHovering)
        .padding(.vertical, LeleleBrowserDesign.Tab.verticalInset)
        .onHoverTracking { isHovering = $0 }
    }
}

private struct SplitHalfTab: View {
    let item: Item
    let zoneID: DropZoneID

    @Environment(TabsController.self) private var tabs
    @ObservedObject private var dragSession = LeleleBrowserDragSessionManager.shared

    var body: some View {
        let session = tabs.session(for: item.id)
        LeleleBrowserDragSourceView(
            item: LeleleBrowserDragItem(tabId: item.id, title: tabs.title(for: item), urlString: tabs.currentURL(for: item)?.absoluteString ?? ""),
            icon: session?.favicon,
            zoneID: zoneID,
            manager: dragSession
        ) {
            SplitHalfLabel(item: item)
        }
        .opacity(dragSession.draggedItem?.tabId == item.id ? LeleleBrowserDesign.Surface.unloadedOpacity : 1)
    }
}
