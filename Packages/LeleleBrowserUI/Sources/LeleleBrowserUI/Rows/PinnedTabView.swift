// Licensed under GPL-3.0. See LICENSE.
//
//  PinnedButtonView.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 30/07/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserTabsCore

public struct PinnedTabView<Icon: View>: View {
    var tabName: String
    var tabURL: String
    var tabIcon: Icon
    var isActive: Bool
    var isUnloaded: Bool = false
    /// The favorite's open page has left its pinned URL; hovering shows a reset button.
    var hasLeftPinnedURL: Bool = false
    var onResetToPinnedURL: () -> Void = {}
    /// The space theme's tile colors, as in Arc. Nil falls back to the neutral fills.
    var colors: SpaceTheme.TileColors?
    /// Host whose blurred favicon glows behind the tile. Nil for neutral tiles.
    var glowHost: String?
    /// The window is inactive.
    var isDimmed: Bool = false
    var action: () -> Void

    @State private var isHovered: Bool = false
    @State private var glow: CGImage?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        tabName: String,
        tabURL: String,
        tabIcon: Icon,
        isActive: Bool,
        isUnloaded: Bool = false,
        hasLeftPinnedURL: Bool = false,
        onResetToPinnedURL: @escaping () -> Void = {},
        colors: SpaceTheme.TileColors? = nil,
        glowHost: String? = nil,
        isDimmed: Bool = false,
        action: @escaping () -> Void
    ) {
        self.tabName = tabName
        self.tabURL = tabURL
        self.tabIcon = tabIcon
        self.isActive = isActive
        self.isUnloaded = isUnloaded
        self.hasLeftPinnedURL = hasLeftPinnedURL
        self.onResetToPinnedURL = onResetToPinnedURL
        self.colors = colors
        self.glowHost = glowHost
        self.isDimmed = isDimmed
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                    .fill(backgroundColor)
                    .animation(LeleleBrowserDesign.Motion.hover(isHovered), value: isHovered)
                if let glow, colors != nil {
                    glowImage(glow)
                        .opacity(LeleleBrowserDesign.Surface.favoriteGlowOpacity(dark: colorScheme == .dark, hovered: isHovered, dimmed: isDimmed))
                        .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
                        .allowsHitTesting(false)
                }
                if isActive, let colors {
                    if let glow, !isDimmed {
                        glowImage(glow)
                            .mask(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                                .strokeBorder(Color.black, lineWidth: LeleleBrowserDesign.Size.favoriteBorder))
                            .allowsHitTesting(false)
                    } else {
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                            .strokeBorder(Color(colors.selectedBorder).opacity(isDimmed ? LeleleBrowserDesign.Surface.favoriteDimmedBorderOpacity : 1),
                                          lineWidth: LeleleBrowserDesign.Size.favoriteBorder)
                    }
                }

                tabIcon
                    .frame(height: LeleleBrowserDesign.Size.essentialsFavicon)
                    .opacity(isUnloaded ? LeleleBrowserDesign.Surface.unloadedOpacity : 1)
            }
            .overlay(alignment: .topTrailing) {
                if hasLeftPinnedURL && isHovered {
                    Button(action: onResetToPinnedURL) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(LeleleBrowserDesign.Font.caption)
                            .foregroundStyle(.primary)
                            .frame(width: LeleleBrowserDesign.Size.cornerButton, height: LeleleBrowserDesign.Size.cornerButton)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Reset to Pinned URL")
                    .padding(LeleleBrowserDesign.Spacing.xxs)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: LeleleBrowserDesign.Size.favoriteTile)
            .frame(minWidth: LeleleBrowserDesign.Size.favoriteTile)
            .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
            .modifier(TileSelection(isActive: isActive, themed: colors != nil))
        }
        // The action is a selection, safe to run on the press and again on the release.
        .buttonStyle(LeleleBrowserPressButtonStyle(onPress: action))
        .onHoverTracking { hovering in
            self.isHovered = hovering
        }
        .task(id: wantsGlow ? glowHost : nil) {
            glow = nil
            guard wantsGlow, let glowHost else { return }
            glow = await FaviconGlow.shared.image(forHost: glowHost)
        }
    }

    private var wantsGlow: Bool { colors != nil && !reduceTransparency }

    private func glowImage(_ image: CGImage) -> some View {
        // Fills the tile's own frame; on its own, scaledToFill grows the tile with the sidebar's width.
        Color.clear
            .overlay {
                Image(decorative: image, scale: LeleleBrowserDesign.Size.favoriteGlowScale)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }

    //MARK: - Colors
    /// Unthemed and selected: clear, since `leleleRowSelection` draws the raised surface.
    private var backgroundColor: Color {
        if let colors {
            if isActive { return LeleleBrowserDesign.Surface.favoriteSelectedFill(dark: colorScheme == .dark, dimmed: isDimmed) }
            return Color(isHovered ? colors.hoverFill : colors.fill)
        }
        return isActive ? .clear : (isHovered ? LeleleBrowserDesign.Surface.fillPressed : LeleleBrowserDesign.Surface.fill)
    }
}

/// A themed tile is flat: fill and border only, no blur, no shadow. Without a theme it keeps
/// the raised selection.
private struct TileSelection: ViewModifier {
    let isActive: Bool
    let themed: Bool

    func body(content: Content) -> some View {
        if themed {
            content
        } else {
            content
                .leleleRowSelection(isActive, radius: LeleleBrowserDesign.Radius.lg)
                .leleleElevation(isActive ? .raised : .flat)
        }
    }
}
