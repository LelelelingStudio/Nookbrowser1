// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarMenuSpacesTab.swift
//  LeleleBrowser
//
//  The library's Spaces page: every space side by side on its own theme, with its profile,
//  its pinned folders and tabs, and a way into the theme editor. A click opens the space.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SidebarMenuSpacesTab: View {
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState

    let onOpenSpace: (UUID) -> Void
    let onNewSpace: () -> Void

    private let columnWidth: CGFloat = 300
    private let addSize: CGFloat = 32

    var body: some View {
        // Arc's layout: each space as a full-height column of its own sidebar, side by side,
        // with a round add button after the last.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: LeleleBrowserDesign.Spacing.lg) {
                ForEach(tabs.switchableSpaces(for: windowState).filter { !$0.isAgent }) { space in
                    SpaceColumn(space: space, isCurrent: space.id == windowState.spaceID) {
                        onOpenSpace(space.id)
                    }
                    .frame(width: columnWidth)
                    .frame(maxHeight: .infinity)
                }
                Button(action: onNewSpace) {
                    Image(systemName: "plus")
                        .font(.system(size: LeleleBrowserDesign.Size.spaceIcon, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: addSize, height: addSize)
                        .background(Color.black, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(PressScale())
                .help("New Space")
                .accessibilityLabel("New Space")
            }
            .padding(LeleleBrowserDesign.Spacing.lg)
        }
    }
}

private struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(LeleleBrowserDesign.Motion.quick, value: configuration.isPressed)
    }
}

private struct SpaceColumn: View {
    @Environment(TabsController.self) private var tabs

    let space: SpaceRecord
    let isCurrent: Bool
    let onOpen: () -> Void

    @State private var isHovering = false
    @State private var showThemeEditor = false

    var body: some View {
        let pinned = tabs.children(of: .pinned(spaceID: space.id))
        let open = tabs.children(of: .tabs(spaceID: space.id))
        VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.rowGap) {
            header
                .padding(.bottom, LeleleBrowserDesign.Spacing.md)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.rowGap) {
                    ForEach(pinned) { item in row(item) }
                    if !pinned.isEmpty && !open.isEmpty {
                        Rectangle()
                            .fill(LeleleBrowserDesign.Surface.hairline)
                            .frame(height: 1)
                            .padding(.vertical, LeleleBrowserDesign.Spacing.sm)
                    }
                    ForEach(open) { item in row(item) }
                }
            }
            Spacer(minLength: 0)
            HStack {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                Spacer()
                Image(systemName: "ellipsis")
            }
            .font(.system(size: LeleleBrowserDesign.Size.rowGlyph, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, LeleleBrowserDesign.Spacing.xs)
            .accessibilityHidden(true)
        }
        .padding(LeleleBrowserDesign.Spacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            // Each column on its own space's color, darkened like Arc's so the library reads as one.
            SpaceChromeBackground(theme: space.theme, accent: space.accentColor, isActive: true, blursBehind: false)
                .overlay(Color.black.opacity(0.12))
                .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
        }
        .overlay {
            LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                .strokeBorder(isCurrent ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1.5)
        }
        .spaceThemeAppearance(space.theme)
        .scaleEffect(isHovering ? 1.005 : 1)
        .animation(LeleleBrowserDesign.Motion.hover(isHovering), value: isHovering)
        .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
        .onTapGesture(perform: onOpen)
        .onHoverTracking { isHovering = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(space.name)
    }

    private var header: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Circle()
                .fill(space.accentColor)
                .frame(width: LeleleBrowserDesign.Spacing.md, height: LeleleBrowserDesign.Spacing.md)
            Text(space.name)
                .font(LeleleBrowserDesign.Font.title)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let profile = tabs.profiles.first(where: { $0.spaceIDs.contains(space.id) }) {
                Label(profile.name, systemImage: "person.crop.circle")
                    .font(LeleleBrowserDesign.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Button("Edit Theme Color…", systemImage: "paintbrush.pointed") { showThemeEditor = true }
                .labelStyle(.iconOnly)
                .buttonStyle(LeleleBrowserIconButtonStyle(size: LeleleBrowserDesign.Size.rowButton))
                .foregroundStyle(.secondary)
                .help("Edit Theme Color…")
                .popover(isPresented: $showThemeEditor, arrowEdge: .bottom) {
                    SpaceThemeEditor(space: space)
                        .environment(tabs)
                }
        }
    }

    private func row(_ item: Item) -> some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.md) {
            if isFolder(item) {
                Image(systemName: "folder.fill")
                    .font(.system(size: LeleleBrowserDesign.Size.favicon - 2))
                    .foregroundStyle(.primary)
                    .frame(width: LeleleBrowserDesign.Size.favicon, height: LeleleBrowserDesign.Size.favicon)
            } else {
                ItemFavicon(item: item, session: tabs.session(for: item.id))
                    .frame(width: LeleleBrowserDesign.Size.favicon, height: LeleleBrowserDesign.Size.favicon)
                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xs))
            }
            Text(tabs.title(for: item))
                .font(LeleleBrowserDesign.Font.body)
                .fontWeight(isFolder(item) ? .semibold : .regular)
                .lineLimit(1)
        }
        .frame(height: LeleleBrowserDesign.Size.row)
    }

    private func isFolder(_ item: Item) -> Bool {
        if case .folder = item.kind { return true }
        return false
    }
}
