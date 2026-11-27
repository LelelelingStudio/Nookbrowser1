// Licensed under GPL-3.0. See LICENSE.
//
//  View+Surface.swift
//  LeleleBrowser
//
//  The surface recipes every layer goes through. LeleleBrowser draws no Liquid Glass: floating layers
//  are solid cards, sidebar chrome and rows are Surface fills.
//

import SwiftUI

private struct DefaultSpaceThemeKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// True while the chrome shows a space with no custom theme.
    var leleleUsesDefaultSpaceTheme: Bool {
        get { self[DefaultSpaceThemeKey.self] }
        set { self[DefaultSpaceThemeKey.self] = newValue }
    }
}

public extension View {
    /// A soft page-frame shadow, drawn separately from live WebKit content.
    /// Removing the silhouette's fill keeps split gutters transparent to the window theme.
    func leleleWebPageShadow<S: Shape>(in shape: S, enabled: Bool = true) -> some View {
        background {
            if enabled {
                shape.fill(Color.black)
                    .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0)
                    .overlay {
                        shape.fill(Color.black).blendMode(.destinationOut)
                    }
                    // Only the shadow is composited; the page and its video layers
                    // remain outside this group.
                    .compositingGroup()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    /// A layer that floats over content: solid raised card, hairline edge, floating shadow.
    func leleleFloatingSurface<S: InsettableShape>(in shape: S) -> some View {
        self.clipShape(shape)
            .background(shape.fill(LeleleBrowserDesign.Surface.raised))
            .overlay(shape.strokeBorder(LeleleBrowserDesign.Surface.hairline, lineWidth: LeleleBrowserDesign.Size.hairlineWidth))
            .leleleElevation(.floating)
    }

    /// Controls over video: a dark scrim, whatever the page or appearance.
    func leleleMediaControl<S: Shape>(in shape: S) -> some View {
        background(shape.fill(LeleleBrowserDesign.Surface.mediaScrim))
    }

    /// Anything chosen from a set outside the tab list (Settings sidebar, library tabs, history):
    /// a solid raised fill and hairline, readable on plain backgrounds. Tab rows use
    /// `leleleTabSurface`. Branch-free; the row applies its own `.raised` elevation.
    func leleleRowSelection(_ isSelected: Bool, radius: CGFloat = LeleleBrowserDesign.Radius.md) -> some View {
        let shape = LeleleBrowserDesign.Radius.shape(radius)
        return background(shape.fill(isSelected ? LeleleBrowserDesign.Surface.raised : .clear))
            .overlay(shape.strokeBorder(LeleleBrowserDesign.Surface.hairline.opacity(isSelected ? 1 : 0), lineWidth: LeleleBrowserDesign.Size.hairlineWidth))
    }

    /// A sidebar chrome control or group: history, sidebar and AI toggles, bottom bar buttons,
    /// search fields, filter chips. `tint` marks the chosen one of a set.
    func leleleControlSurface<S: InsettableShape>(_ isOn: Bool = true, tint: Color? = nil, in shape: S) -> some View {
        background(shape.fill(isOn ? (tint?.opacity(LeleleBrowserDesign.Surface.tintOpacity) ?? LeleleBrowserDesign.Surface.fill) : .clear))
    }
}

/// Native tab interaction; Reduce Motion keeps the pressed card at its original scale.
public struct LeleleBrowserTabButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let onPress: (() -> Void)?

    /// `onPress` runs as the button goes down, ahead of the action on release.
    public init(onPress: (() -> Void)? = nil) { self.onPress = onPress }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? LeleleBrowserDesign.Tab.pressScale : 1)
            .animation(reduceMotion ? nil : LeleleBrowserDesign.Motion.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { onPress?() } }
    }
}

/// A plain button that reports the press, so a favorite selects before the click ends.
public struct LeleleBrowserPressButtonStyle: ButtonStyle {
    private let onPress: () -> Void

    public init(onPress: @escaping () -> Void) { self.onPress = onPress }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { onPress() } }
    }
}

public extension View {
    /// Tab card shared by sidebar rows, split rows and native drag previews: the theme-tinted
    /// selection fill, a hover fill, and a continuous `Tab.radius` shape.
    func leleleTabSurface(selected: Bool, hovered: Bool = false) -> some View {
        let shape = LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Tab.radius)
        return clipShape(shape)
            .background(shape.fill(selected ? LeleleBrowserDesign.Surface.selection : hovered ? LeleleBrowserDesign.Surface.fill : .clear))
            .contentShape(shape)
    }
}
