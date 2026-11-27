// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowserDragSourceView.swift
//  LeleleBrowser
//

import SwiftUI
import AppKit
import LeleleBrowserTabsCore
import LeleleBrowserWeb

// MARK: - Drag Source Coordinator (NSDraggingSource)

@MainActor
final class LeleleBrowserDragSourceCoordinator: NSObject, NSDraggingSource {
    var item: LeleleBrowserDragItem
    var icon: Image?
    var zoneID: DropZoneID
    var theme: SpaceTheme?
    var accent: Color = .gray
    var colorScheme: ColorScheme = .light
    let manager: LeleleBrowserDragSessionManager

    init(item: LeleleBrowserDragItem, icon: Image?, zoneID: DropZoneID, manager: LeleleBrowserDragSessionManager) {
        self.item = item
        self.icon = icon
        self.zoneID = zoneID
        self.manager = manager
    }

    nonisolated func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .withinApplication ? .move : .copy
    }

    // NSDraggingSource is declared NS_SWIFT_UI_ACTOR, so these run on the main actor
    // statically. Marking them nonisolated and hopping back with assumeIsolated added a
    // dynamic executor check that segfaults after any ObjC exception has unwound a
    // main-actor task (see ExternalMiniWindowManager.items(for:) for the same fix).
    func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        manager.updateCursorScreenPosition(screenPoint)
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        manager.nativeDragEnded()
    }
}

// MARK: - DragSourceNSView

final class LeleleBrowserDragSourceNSView: NSView {
    var coordinator: LeleleBrowserDragSourceCoordinator?
    private(set) var registrationId: UUID?

    func registerWithManager() {
        guard let coordinator = coordinator else { return }
        let id = UUID()
        registrationId = id
        coordinator.manager.registerDragSource(self, id: id)
    }

    func unregisterFromManager() {
        guard let id = registrationId, let coordinator = coordinator else { return }
        coordinator.manager.unregisterDragSource(id: id)
        registrationId = nil
    }

    func initiateDrag(with event: NSEvent, mouseDownEvent: NSEvent?) {
        guard let coordinator = coordinator else { return }

        // Capture screen position from the event for preview window positioning
        let screenPoint: NSPoint
        if let window = self.window {
            screenPoint = window.convertPoint(toScreen: event.locationInWindow)
        } else {
            screenPoint = NSEvent.mouseLocation
        }

        coordinator.manager.beginDrag(
            item: coordinator.item,
            icon: coordinator.icon,
            from: coordinator.zoneID,
            cursorScreenPoint: screenPoint,
            grabScreenPoint: mouseDownEvent.flatMap { window?.convertPoint(toScreen: $0.locationInWindow) } ?? screenPoint,
            sourceFrame: window?.convertToScreen(convert(bounds, to: nil)) ?? .zero,
            window: window,
            theme: coordinator.theme,
            accent: coordinator.accent,
            colorScheme: coordinator.colorScheme
        )

        let pasteboardItem = NSPasteboardItem()
        if let data = try? JSONEncoder().encode(coordinator.item) {
            pasteboardItem.setData(data, forType: .leleleTabItem)
        }
        pasteboardItem.setString(coordinator.item.tabId.uuidString, forType: .string)

        let transparentImage = NSImage(size: NSSize(width: 1, height: 1))

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(
            NSRect(x: 0, y: 0, width: 1, height: 1),
            contents: transparentImage
        )

        beginDraggingSession(with: [draggingItem], event: event, source: coordinator)
    }
}

// MARK: - Invisible Anchor (NSViewRepresentable)

private struct DragSourceAnchor: NSViewRepresentable {
    let item: LeleleBrowserDragItem
    let icon: Image?
    let zoneID: DropZoneID
    let manager: LeleleBrowserDragSessionManager
    let theme: SpaceTheme?
    let accent: Color
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> LeleleBrowserDragSourceNSView {
        let view = LeleleBrowserDragSourceNSView()
        view.coordinator = context.coordinator
        context.coordinator.theme = theme
        context.coordinator.accent = accent
        context.coordinator.colorScheme = colorScheme
        view.registerWithManager()
        return view
    }

    func updateNSView(_ nsView: LeleleBrowserDragSourceNSView, context: Context) {
        context.coordinator.item = item
        context.coordinator.icon = icon
        context.coordinator.zoneID = zoneID
        context.coordinator.theme = theme
        context.coordinator.accent = accent
        context.coordinator.colorScheme = colorScheme
    }

    static func dismantleNSView(_ nsView: LeleleBrowserDragSourceNSView, coordinator: LeleleBrowserDragSourceCoordinator) {
        nsView.unregisterFromManager()
    }

    func makeCoordinator() -> LeleleBrowserDragSourceCoordinator {
        LeleleBrowserDragSourceCoordinator(item: item, icon: icon, zoneID: zoneID, manager: manager)
    }
}

// MARK: - LeleleBrowserDragSourceView

struct LeleleBrowserDragSourceView<Content: View>: View {
    let item: LeleleBrowserDragItem
    let icon: Image?
    let zoneID: DropZoneID
    let manager: LeleleBrowserDragSessionManager
    @ViewBuilder let content: () -> Content
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(\.colorScheme) private var colorScheme

    private var space: SpaceRecord? {
        windowState.isIncognito ? nil : windowState.spaceID.flatMap { tabs.space($0) }
    }

    var body: some View {
        content()
            .background(
                DragSourceAnchor(
                    item: item,
                    icon: icon,
                    zoneID: zoneID,
                    manager: manager,
                    theme: space?.theme,
                    accent: space?.accentColor ?? .gray,
                    colorScheme: colorScheme
                )
            )
    }
}
