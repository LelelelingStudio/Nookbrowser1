// Licensed under GPL-3.0. See LICENSE.
//
//  SpaceCreationSidebar.swift
//  LeleleBrowser
//
//  Create a Space, in the sidebar: name, profile and theme, with the window already showing
//  the theme. Open while `BrowserWindowState.spaceDraftTheme` is set.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserSettings
import LeleleBrowserTabsCore
import LeleleBrowserWeb
import LeleleBrowserUI

struct SpaceCreationSidebar: View {
    @Environment(TabsController.self) private var tabs
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(\.leleleSettings) private var settings
    @Environment(\.tabActions) private var actions

    @State private var name = ""
    @State private var icon = ""
    @State private var showIconPicker = false
    /// The space whose logins the new one shares; nil is a new profile.
    @State private var loginsFrom: UUID?
    /// For a new profile: the extension set it syncs with; nil is Separate.
    @State private var extensionsFrom: UUID?
    @State private var showThemeEditor = false
    @FocusState private var nameFocused: Bool

    private let cardSize = CGSize(width: 44, height: 56)

    private var theme: SpaceTheme { windowState.spaceDraftTheme ?? SpaceTheme(points: [.center]) }

    private var draftTheme: Binding<SpaceTheme> {
        Binding(get: { theme }, set: { windowState.spaceDraftTheme = $0 })
    }

    var body: some View {
        VStack(spacing: LeleleBrowserDesign.Spacing.lg) {
            header
                .padding(.top, LeleleBrowserDesign.Spacing.xxxl)
                .padding(.bottom, LeleleBrowserDesign.Spacing.md)

            nameField
            profileRow
            if loginsFrom == nil, tabs.profiles.count > 0 { extensionsRow }
            themeRow

            Spacer(minLength: 0)

            VStack(spacing: LeleleBrowserDesign.Spacing.sm) {
                Button(action: create) {
                    Text("Create Space")
                        .font(LeleleBrowserDesign.Font.body)
                        .frame(maxWidth: .infinity)
                        .frame(height: LeleleBrowserDesign.Size.row + LeleleBrowserDesign.Spacing.xs)
                }
                .buttonStyle(CreateButtonStyle(fill: accent, darkText: accentRGB.luminance > 0.45))
                .keyboardShortcut(.defaultAction)

                Button("Cancel", action: cancel)
                    .buttonStyle(.plain)
                    .font(LeleleBrowserDesign.Font.body)
                    .foregroundStyle(.secondary)
                    .frame(height: LeleleBrowserDesign.Size.row)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(.horizontal, LeleleBrowserDesign.Spacing.sidebarInset)
        .padding(.bottom, LeleleBrowserDesign.Spacing.lg)
        .onAppear {
            loginsFrom = windowState.spaceID.flatMap { tabs.space($0) }.flatMap { $0.isAgent ? nil : $0.id }
            extensionsFrom = ExtensionSetRegistry.shared.setID(for: windowState)
            nameFocused = true
        }
        .onExitCommand(perform: cancel)
    }

    // MARK: - Header

    /// Three cards fanned out in the theme's colors, the way spaces stack in the switcher.
    private var header: some View {
        VStack(spacing: LeleleBrowserDesign.Spacing.md) {
            ZStack {
                // Back cards in the theme's first and last color, a neutral card in front.
                let cards = [theme.points[0], .center, theme.points[theme.points.count - 1]]
                ForEach(0..<3, id: \.self) { index in
                    LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md)
                        .fill(Color(hex: SpaceTheme.swatchColor(cards[index]).hex))
                        .overlay(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md).strokeBorder(LeleleBrowserDesign.Surface.hairline))
                        .frame(width: cardSize.width, height: cardSize.height)
                        .rotationEffect(.degrees(Double(index - 1) * 12))
                        .offset(x: CGFloat(index - 1) * LeleleBrowserDesign.Spacing.xl, y: index == 1 ? -LeleleBrowserDesign.Spacing.xs : 0)
                        .zIndex(index == 1 ? 1 : 0)
                        .leleleElevation(.raised)
                }
            }
            .frame(height: cardSize.height + LeleleBrowserDesign.Spacing.lg)
            .animation(LeleleBrowserDesign.Motion.standard, value: theme.points)

            Text("Create a Space")
                .font(LeleleBrowserDesign.Font.titleLarge)
            Text("Organize your tabs into a new space")
                .font(LeleleBrowserDesign.Font.bodyRegular)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Fields

    private var nameField: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Button { showIconPicker = true } label: {
                SpaceIcon(icon)
                    .foregroundStyle(icon.isEmpty ? Color(hex: SpaceTheme.accentColor(theme.points[0]).hex) : .secondary)
                    .frame(width: LeleleBrowserDesign.Size.iconButton, height: LeleleBrowserDesign.Size.iconButton)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Space icon")
            .popover(isPresented: $showIconPicker) {
                SpaceIconPicker(icon: $icon, onSelect: { showIconPicker = false })
            }
            TextField("Space name…", text: $name)
                .textFieldStyle(.plain)
                .focused($nameFocused)
                .onSubmit(create)
        }
        .font(LeleleBrowserDesign.Font.body)
        .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
        .frame(height: LeleleBrowserDesign.Size.row + LeleleBrowserDesign.Spacing.xs)
        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
    }

    private var profileRow: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Image(systemName: "person.2")
                .foregroundStyle(.secondary)
            Text("Profile")
            Spacer(minLength: 0)
            Menu {
                ForEach(tabs.profiles) { profile in
                    Button(profile.name) { loginsFrom = profile.spaceIDs.first }
                }
                Divider()
                Button("New Profile") { loginsFrom = nil }
            } label: {
                Text(profileName)
            }
            .menuStyle(.button)
            .buttonStyle(RectNavButtonStyle())
            .fixedSize()
        }
        .font(LeleleBrowserDesign.Font.body)
        .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
        .frame(height: LeleleBrowserDesign.Size.row + LeleleBrowserDesign.Spacing.xs)
        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
    }

    private var extensionOptions: [ExtensionSetOption] {
        ExtensionSetOptions.options(for: nil, profiles: tabs.profiles, sets: settings.extensionSets,
                                    defaultSet: ExtensionSetRegistry.shared.defaultSetID)
    }

    private var extensionsRow: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Image(systemName: "puzzlepiece.extension")
                .foregroundStyle(.secondary)
            Text("Extensions")
            Spacer(minLength: 0)
            Menu {
                ForEach(extensionOptions) { option in
                    Button(option.label) { extensionsFrom = option.set }
                }
            } label: {
                Text(extensionOptions.first { $0.set == extensionsFrom }?.label ?? "Separate")
            }
            .menuStyle(.button)
            .buttonStyle(RectNavButtonStyle())
            .fixedSize()
        }
        .font(LeleleBrowserDesign.Font.body)
        .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
        .frame(height: LeleleBrowserDesign.Size.row + LeleleBrowserDesign.Spacing.xs)
        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
    }

    private var profileName: String {
        guard let loginsFrom else { return "New Profile" }
        return tabs.profiles.first { $0.spaceIDs.contains(loginsFrom) }?.name ?? "New Profile"
    }

    private var themeRow: some View {
        Button {
            showThemeEditor = true
        } label: {
            HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
                Image(systemName: "paintbrush.pointed")
                    .foregroundStyle(.secondary)
                Text("Choose a Theme")
                Spacer(minLength: 0)
                Circle()
                    .fill(accent)
                    .frame(width: LeleleBrowserDesign.Spacing.lg, height: LeleleBrowserDesign.Spacing.lg)
            }
            .font(LeleleBrowserDesign.Font.body)
            .padding(.horizontal, LeleleBrowserDesign.Spacing.rowPadding)
            .frame(height: LeleleBrowserDesign.Size.row + LeleleBrowserDesign.Spacing.xs)
            .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
        }
        .buttonStyle(.plain)
        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
        .popover(isPresented: $showThemeEditor, arrowEdge: .trailing) {
            SpaceThemePanel(theme: draftTheme)
        }
    }

    private var accentRGB: ThemeRGB { SpaceTheme.accentColor(theme.points[0]) }
    private var accent: Color { Color(hex: accentRGB.hex) }

    // MARK: - Actions

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let theme = self.theme
        guard let spaceID = tabs.createSpace(
            name: trimmed.isEmpty ? "New Space" : trimmed,
            icon: icon,
            accentHex: SpaceTheme.accentColor(theme.points[0]).hex,
            after: tabs.orderedSpaces.last { !$0.isAgent }?.id,
            sharingLoginsWith: loginsFrom
        ) else { return }
        tabs.setTheme(theme, forSpace: spaceID)
        if loginsFrom == nil, let profile = tabs.tree.dataStoreID(for: spaceID),
           extensionsFrom != ExtensionSetRegistry.shared.defaultSetID {
            actions?.setExtensionSet(ofProfile: profile, to: extensionsFrom)
        }
        withAnimation(LeleleBrowserDesign.Motion.standard) {
            windowState.spaceDraftTheme = nil
            tabs.setSpace(spaceID, in: windowState)
        }
    }

    private func cancel() {
        withAnimation(LeleleBrowserDesign.Motion.standard) { windowState.spaceDraftTheme = nil }
    }
}

private struct CreateButtonStyle: ButtonStyle {
    let fill: Color
    let darkText: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(darkText ? Color.black : Color.white)
            .background(fill.opacity(configuration.isPressed ? 0.85 : 1), in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(LeleleBrowserDesign.Motion.quick, value: configuration.isPressed)
    }
}
