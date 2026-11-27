// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowserDropZoneHostView.swift
//  LeleleBrowser
//

import SwiftUI
import AppKit

// MARK: - Drop Zone Coordinator

@MainActor
class LeleleBrowserDropZoneCoordinator: NSObject {
    var zoneID: DropZoneID
    var layout: DropLayout
    var onDrop: (UUID, DropPosition) -> Void
    let manager: LeleleBrowserDragSessionManager

    init(zoneID: DropZoneID, layout: DropLayout, manager: LeleleBrowserDragSessionManager, onDrop: @escaping (UUID, DropPosition) -> Void) {
        self.zoneID = zoneID
        self.layout = layout
        self.manager = manager
        self.onDrop = onDrop
    }
}

// MARK: - LeleleBrowserDropZoneNSView

class LeleleBrowserDropZoneNSView: NSView {
    weak var coordinator: LeleleBrowserDropZoneCoordinator?

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard let coordinator = coordinator,
              LeleleBrowserDragItem.fromPasteboard(sender.draggingPasteboard) != nil else { return [] }
        MainActor.assumeIsolated {
            coordinator.manager.cursorEnteredZone(coordinator.zoneID)
        }
        updatePosition(sender)
        return .move
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard let coordinator, LeleleBrowserDragItem.fromPasteboard(sender.draggingPasteboard) != nil else { return [] }
        coordinator.manager.cursorEnteredZone(coordinator.zoneID)
        updatePosition(sender)
        return .move
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        guard let coordinator = coordinator else { return }
        MainActor.assumeIsolated {
            coordinator.manager.cursorExitedZone(coordinator.zoneID)
        }
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let coordinator = coordinator,
              let item = LeleleBrowserDragItem.fromPasteboard(sender.draggingPasteboard) else { return false }
        let point = flippedPoint(sender)
        let width = bounds.width
        MainActor.assumeIsolated {
            let position = LeleleBrowserDragSessionManager.position(in: coordinator.zoneID, layout: coordinator.layout, point: point, width: width)
            let screenFrame = window?.convertToScreen(convert(bounds, to: nil)) ?? .zero
            coordinator.manager.finishDrag(at: position, layout: coordinator.layout, zoneScreenFrame: screenFrame) {
                coordinator.onDrop(item.tabId, position)
            }
        }
        return true
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {}

    private func flippedPoint(_ sender: NSDraggingInfo) -> CGPoint {
        let localPoint = convert(sender.draggingLocation, from: nil)
        return CGPoint(x: localPoint.x, y: bounds.height - localPoint.y)
    }

    private func updatePosition(_ sender: NSDraggingInfo) {
        guard let coordinator = coordinator else { return }
        let point = flippedPoint(sender)
        let width = bounds.width
        MainActor.assumeIsolated {
            coordinator.manager.updateDropPosition(for: coordinator.zoneID, layout: coordinator.layout, localPoint: point, zoneWidth: width)
        }
    }
}

// MARK: - Invisible Drop Zone Anchor (NSViewRepresentable)

private struct DropZoneAnchor: NSViewRepresentable {
    let zoneID: DropZoneID
    let layout: DropLayout
    let manager: LeleleBrowserDragSessionManager
    let onDrop: (UUID, DropPosition) -> Void

    func makeNSView(context: Context) -> LeleleBrowserDropZoneNSView {
        let view = LeleleBrowserDropZoneNSView()
        view.coordinator = context.coordinator
        view.registerForDraggedTypes([.leleleTabItem, .string])
        return view
    }

    func updateNSView(_ nsView: LeleleBrowserDropZoneNSView, context: Context) {
        context.coordinator.zoneID = zoneID
        context.coordinator.layout = layout
        context.coordinator.onDrop = onDrop
    }

    func makeCoordinator() -> LeleleBrowserDropZoneCoordinator {
        LeleleBrowserDropZoneCoordinator(zoneID: zoneID, layout: layout, manager: manager, onDrop: onDrop)
    }
}

// MARK: - LeleleBrowserDropZoneHostView

/// Makes its content a drop target. `onDrop` runs on the main actor with the dragged item id.
struct LeleleBrowserDropZoneHostView<Content: View>: View {
    let zoneID: DropZoneID
    let layout: DropLayout
    let manager: LeleleBrowserDragSessionManager
    let onDrop: (UUID, DropPosition) -> Void
    @ViewBuilder let content: () -> Content

    init(zoneID: DropZoneID, layout: DropLayout, manager: LeleleBrowserDragSessionManager,
         onDrop: @escaping (UUID, DropPosition) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.zoneID = zoneID
        self.layout = layout
        self.manager = manager
        self.onDrop = onDrop
        self.content = content
    }

    /// A row-less target such as a space title or switcher item.
    init(zoneID: DropZoneID, manager: LeleleBrowserDragSessionManager,
         onDrop: @escaping (UUID) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.init(zoneID: zoneID, layout: .none, manager: manager, onDrop: { id, _ in onDrop(id) }, content: content)
    }

    var body: some View {
        content()
            .background(
                DropZoneAnchor(
                    zoneID: zoneID,
                    layout: layout,
                    manager: manager,
                    onDrop: onDrop
                )
            )
    }
}
