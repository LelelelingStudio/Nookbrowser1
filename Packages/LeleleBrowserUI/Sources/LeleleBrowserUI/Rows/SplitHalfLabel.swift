// Licensed under GPL-3.0. See LICENSE.
//
//  SplitHalfLabel.swift
//  LeleleBrowserUI
//
//  One half of the sidebar's split row: everything but the drag source, which is an
//  AppKit view the app wraps around this.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb

public struct SplitHalfLabel: View {
    let item: Item

    @State private var isHovering: Bool = false
    @State private var isCloseHovering: Bool = false
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(\.tabActions) private var actions

    public init(item: Item) {
        self.item = item
    }

    public var body: some View {
        let title = tabs.title(for: item)
        let session = tabs.session(for: item.id)
        Button(action: { tabs.select(item.id, in: windowState) }) {
            HStack(spacing: LeleleBrowserDesign.Spacing.md) {
                ItemFavicon(item: item, session: session)
                    .frame(width: LeleleBrowserDesign.Size.favicon, height: LeleleBrowserDesign.Size.favicon)
                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xs))
                Text(title)
                    .font(LeleleBrowserDesign.Tab.font)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: LeleleBrowserDesign.Spacing.xs)
                if isHovering {
                    Button(action: { tabs.close(item.id) }) {
                        Image(systemName: "xmark")
                            .font(LeleleBrowserDesign.Font.secondary)
                            .foregroundColor(.primary)
                            .frame(width: LeleleBrowserDesign.Size.rowButton, height: LeleleBrowserDesign.Size.rowButton)
                            .background(isCloseHovering ? LeleleBrowserDesign.Surface.fillPressed : Color.clear)
                            .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.sm))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHoverTracking { state in
                        isCloseHovering = state
                    }
                }
            }
            .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHoverTracking { hovering in
            withAnimation(LeleleBrowserDesign.Motion.hover(hovering)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            TabContextMenu(itemID: item.id, context: .split)
                .environment(windowState)
                .environment(tabs)
                .environment(\.tabActions, actions)
        }
        .background(isHovering ? LeleleBrowserDesign.Surface.fill : Color.clear)
    }
}
