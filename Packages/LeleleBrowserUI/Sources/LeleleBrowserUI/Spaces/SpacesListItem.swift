// Licensed under GPL-3.0. See LICENSE.
//
//  SpacesListItem.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 04/08/2025.
//  Refactored by Aether on 15/11/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore
import LeleleBrowserWeb

struct SpacesListItem: View {
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState

    let space: SpaceRecord
    let isActive: Bool
    let selection: Double
    let isFaded: Bool
    /// Draw a plain dot whatever the icon; the Agent space keeps its mark.
    let forceDot: Bool

    @State private var showThemePicker = false
    @State private var showsIconPicker = false
    @Environment(\.tabActions) private var actions

    private let dotSize: CGFloat = LeleleBrowserDesign.Spacing.sm
    private let activeDotSize: CGFloat = LeleleBrowserDesign.Spacing.md
    private let buttonSize: CGFloat

    init(
        space: SpaceRecord,
        isActive: Bool,
        selection: Double? = nil,
        isFaded: Bool,
        buttonSize: CGFloat = LeleleBrowserDesign.Spacing.xxl,
        forceDot: Bool = false
    ) {
        self.forceDot = forceDot
        self.space = space
        self.isActive = isActive
        self.selection = selection ?? (isActive ? 1 : 0)
        self.isFaded = isFaded
        self.buttonSize = buttonSize
    }

    var body: some View {
        Button {
            guard windowState.spaceID != space.id else { return }
            Haptics.alignment()
            withAnimation(LeleleBrowserDesign.Motion.standard) {
                tabs.setSpace(space.id, in: windowState)
            }
        } label: {
            spaceDot
        }
        .labelStyle(.iconOnly)
        .buttonStyle(LeleleBrowserIconButtonStyle(size: buttonSize))
        .layoutPriority(isActive ? 1 : 0)
        .opacity(isFaded ? 0.3 : 1.0)
        .accessibilityLabel(space.name)
        .popover(isPresented: $showThemePicker, arrowEdge: .top) {
            SpaceThemeEditor(space: space)
                .environment(tabs)
        }
        .popover(isPresented: $showsIconPicker) {
            SpaceIconPicker(icon: Binding(
                get: { tabs.space(space.id)?.icon ?? space.icon },
                set: { tabs.updateSpace(space.id, name: nil, icon: $0, accentHex: nil) }
            ), onSelect: { showsIconPicker = false })
        }
        .contextMenu {
            if !space.isAgent {
                Button("Change Icon or Emoji…", systemImage: "face.smiling") {
                    DispatchQueue.main.async { showsIconPicker = true }
                }
                Divider()
            }
            SpaceContextMenu(
                space: space,
                onEditThemeColor: { showThemePicker = true },
                canDelete: tabs.switchableSpaces(for: windowState).count > 1,
                onOpenSettings: { actions?.openSpaceSettings() },
                onDeleteSpace: { tabs.deleteSpace(space.id) }
            )
            .environment(tabs)
            .environment(\.tabActions, actions)
        }
    }

    // MARK: - Dot

    @ViewBuilder
    private var spaceDot: some View {
        if space.isAgent {
            Image(systemName: "sparkles")
                .font(.system(size: LeleleBrowserDesign.Size.spaceIcon, weight: .semibold))
                .foregroundStyle(LeleleBrowserDesign.Surface.agentGradient)
                .opacity(LeleleBrowserDesign.Surface.agentIconInactiveOpacity + (1 - LeleleBrowserDesign.Surface.agentIconInactiveOpacity) * selection)
                .animation(LeleleBrowserDesign.Motion.standard, value: isActive)
        } else if forceDot || SpaceIcon.isDot(space.icon) {
            plainDot
        } else {
            SpaceIcon(space.icon)
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
        }
    }

    private var plainDot: some View {
        let size = dotSize + (activeDotSize - dotSize) * selection
        return Circle()
            .fill(.tertiary)
            .overlay(Circle().fill(space.accentColor).opacity(selection))
            .frame(width: size, height: size)
            .animation(LeleleBrowserDesign.Motion.standard, value: isActive)
    }
}
